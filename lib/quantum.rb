# 服务间后台任务消息通信模块，用于不同应用间的消息投递
# 基于 Sidekiq ActiveJob
module Quantum
  # 实验功能，用于指定异步任务回调
  # 目前只在稿件入库打股码时用到
  # 用例参考：
  # 生产者
  # message = Oj.dump({
  #   callback: {
  #     from:  'smaug',
  #     to:    'desmodus',
  #     event: 'add_stock_codes',
  #     queue: 'push_to_self',
  #     job:   'AddStockCodesImportJob',
  #     data:  attributes
  #   },
  #
  #   content: attributes['content']
  # }.as_json)
  #
  # Quantum.mail(
  #   from: :desmodus,
  #   to: :smaug,
  #   event: :add_stock_codes,
  #   queue: :smaug_add_stock_codes,
  #   job: 'AddStockCodesJob',
  #   message: message
  # )
  #
  # 消费者
  # class AddStockCodesJob < ActiveJob::Base
  #   include Quantum::Callback
  #   queue_as :smaug_add_stock_codes
  #
  #   def perform(message)
  #     data = Oj.load(message)
  #     result_data = JYDB::AddStockCode::CreateService.new(content: data['content']).to_hash
  #     callback = extract_callback(message)
  #
  #     result_message = Oj.dump({
  #       data: data.dig('callback', 'data'),
  #       result: result_data
  #     }.as_json)
  #
  #     Quantum.mail(callback.merge(message: result_message))
  #   end
  # end
  module Callback
    def extract_callback(message)
      data = Oj.load(message)
      callback = data['callback']

      {
        from:  callback['from'],
        to:    callback['to'],
        event: callback['event'],
        queue: callback['queue'],
        job:   callback['job'],
      }
    end
  end

  # 帮助创建存储进程使用的 client
  module Client
    def self.create(service_name, redis_url:, size: 5, timeout: 5)
      return if redis_url.blank?
      @clients ||= {}
      @clients[service_name] =
        Sidekiq::Client.new(ConnectionPool.new(size: size, timeout: timeout) do
          Redis.new(url: redis_url)
        end)
      @clients[service_name]
    end

    def self.find(service_name)
      @clients ||= {}
      @clients[service_name]
    end
  end

  class << self
    # 给其他服务推送消息
    #
    # - 先注册再推送
    #
    # data = {id: 1}
    #
    # Quantum.config do
    #   tunnel from: :invest, to: :bus do
    #     event :publish, queue: :bus_input, job: 'Gateway::PublishJob'
    #   end
    # end
    #
    # Quantum.mail(from: :invest, to: :bus, event: :publish, message: Oj.dump(data.as_json))
    #
    # 指定投递的 Redis 实例 [ref] (https://github.com/mperham/sidekiq/wiki/Sharding)
    #
    # REDIS_A = ConnectionPool.new { Redis.new(...) }
    # sidekiq_client = Sidekiq::Client.new(REDIS_A)
    #
    # Quantum.config do
    #   tunnel from: :invest, to: :bus, client: sidekiq_client do
    #     event :publish, queue: :bus_input, job: 'Gateway::PublishJob'
    #   end
    # end
    #
    # data = {id: 1}
    # Quantum.mail(from: :invest, to: :bus, event: :publish, message: Oj.dump(data.as_json))
    #
    # - 动态推送
    #
    # 需要指定 queue 和 job，可选指定 client
    # 推送的时候 client 不会固化下来，queue 和 job 会固化
    #
    # data = {id: 1}
    #
    # 使用默认的 client
    #
    # Quantum.mail(
    #   from: :invest,
    #   to: :bus,
    #   event: :publish,
    #   queue: :bus_input,
    #   job: 'Gateway::PublishJob',
    #   message: Oj.dump(data.as_json)
    # )
    #
    # 指定投递的 Redis 实例 [ref] (https://github.com/mperham/sidekiq/wiki/Sharding)
    #
    # REDIS_A = ConnectionPool.new { Redis.new(...) }
    # sidekiq_client = Sidekiq::Client.new(REDIS_A)
    #
    # data = {id: 1}
    # Quantum.mail(
    #   from: :invest,
    #   to: :bus,
    #   event: :publish,
    #   client: sidekiq_client,
    #   queue: :bus_input,
    #   job: 'Gateway::PublishJob',
    #   message: Oj.dump(data.as_json)
    # )
    def mail(from:, to:, event:, message:, client: nil, queue: nil, job: nil)
      job_to_perform =
        fetch_job_class(from, to, event) ||
        initialize_job_class!(from: from, to: to, event: event, queue: queue, job: job)

      job_client =
        client ||
        fetch_job_client(from, to, event) ||
        Client.find(to)

      case job_client
      when Sidekiq::Client
        # [ref] (https://github.com/rails/rails/blob/60809e0e1f36da730d0765a1dd781c52366053fb/activejob/lib/active_job/enqueuing.rb#L57)
        job_instance = job_to_perform.new(*message)

        # [ref] (https://github.com/rails/rails/blob/1f41f2ac6dc659be9aabcd4cc096b31aa150eb2b/activejob/lib/active_job/queue_adapters/sidekiq_adapter.rb#L22)
        job_client.push \
          "class"   => ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper,
          "wrapped" => job_instance.class.name,
          "queue"   => job_instance.queue_name,
          "args"    => [ job_instance.serialize ]
      else
        job_to_perform.perform_later(*message)
      end
    end

    # 配置开始 DSL
    # Quantum.config do
    #   tunnel from: :invest, to: :bus do
    #     event :publish,   queue: :bus_input, job: 'Gateway::PublishJob'
    #     event :depublish, queue: :bus_input, job: 'Gateway::DepublishJob'
    #   end
    # end
    def config(&block)
      class_exec(&block)
    end

    # 创建全局客户端 DSL
    # Quantum.config do
    #   client :bi, redis_url: ENV.fetch('QUANTUM_REDIS_URL_BI'), size: 20
    #
    #   tunnel from: :newsfeed, to: :bi do
    #     event :fetch_one_error, queue: :"#{ENV['RAILS_ENV']}_bi_default", job: 'Newsfeed::CreateErrorRecordJob'
    #   end
    # end
    def client(service_name, redis_url:, size: 5, timeout: 5)
      Client.create(service_name, redis_url: redis_url, size: 5, timeout: 5)
    end

    # 连接到其他的服务 DSL
    # Quantum.config do
    #   tunnel from: :invest, to: :bus do
    #     event :publish,   queue: :bus_input, job: 'Gateway::PublishJob'
    #     event :depublish, queue: :bus_input, job: 'Gateway::DepublishJob'
    #   end
    # end
    def tunnel(from:, to:, client: nil, &block)
      @from = from
      @to = to
      @client = client
      class_exec(&block)
    end

    # 注册事件 DSL
    # Quantum.config do
    #   tunnel from: :invest, to: :bus do
    #     event :publish,   queue: :bus_input, job: 'Gateway::PublishJob'
    #     event :depublish, queue: :bus_input, job: 'Gateway::DepublishJob'
    #   end
    # end
    def event(name, queue:, job:)
      initialize_job_client(from: @from, to: @to, event: name, client: @client)
      initialize_job_class!(from: @from, to: @to, event: name, queue: queue, job: job)
    end

    # private
    def initialize_job_client(from:, to:, event:, client:)
      key = job_key(from, to, event)
      @job_clients ||= {}
      @job_clients[key] = client
    end

    # private
    def initialize_job_class!(from:, to:, event:, queue:, job:)
      key = job_key(from, to, event)

      if queue.nil? || job.nil?
        fail "Quantum #{key} does not registered. Should provide 'queue' and 'job' parameter."
      end

      @job_define ||= {}
      @jobs ||= []

      fail 'Quantum should not redefine a event' unless @job_define[key].nil?
      fail 'Quantum should not use a job twice'  if @jobs.any? { |j| j.to_s == job }

      define_job_class(queue, job) unless Object.const_defined?(job)

      job_class = Object.const_get(job)
      @job_define[key] = job_class
      @jobs << job_class.to_s

      job_class
    end

    # private
    def define_job_class(queue, job)
      job_class = Class.new(ActiveJob::Base) do
                    queue_as queue
                    def perform(*args); end
                  end

      leaf = job.split('::').last

      job.split('::').reduce(Object) do |m, c|

        unless m.const_defined?(c)
          if c == leaf
            m.const_set(c, job_class)
          else
            m.const_set(c, Module.new)
          end
        end

        m.const_get(c)
      end
    end

    # private
    def fetch_job_class(from, to, event)
      return if @job_define.nil?
      key = job_key(from, to, event)
      @job_define[key]
    end

    # private
    def fetch_job_client(from, to, event)
      return if @job_clients.nil?
      key = job_key(from, to, event)
      @job_clients[key]
    end

    # private
    def job_key(from, to, event)
      [from, to, event].join(':')
    end
  end
end
