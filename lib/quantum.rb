# Example (in your initializers/quantum.rb)
# ---
# Quantum.config do
#   tunnel from: :invest, to: :bus do
#     event :publish,   queue: :bus_input, job: 'Gateway::PublishJob'
#     event :depublish, queue: :bus_input, job: 'Gateway::DepublishJob'
#   end
# end
#
# (when you want to sent a message to other server)
# ---
# Quantum.mail(from: :invest, to: :bus, event: :publish, message: Oj.dump(data.as_json))

module Quantum
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

  # 支持动态定义
  def self.mail(from:, to:, event:, message:, queue: nil, job: nil)
    key = job_key(from, to, event)

    @job_define.fetch(key) do
      if queue.nil? || job.nil?
        fail "Quantum #{key} does not registered."
      else
        self.tunnel(from: from, to: to) do
          self.event(event, queue: queue, job: job)
        end

        @job_define.fetch(key) { fail "Quantum #{key} does not registered." }
      end
    end.perform_later(*message)
  end

  def self.config(&block)
    class_exec(&block)
  end

  def self.tunnel(from:, to:, &block)
    @from = from
    @to = to
    class_exec(&block)
  end

  def self.event(name, queue:, job:)
    key = job_key(@from, @to, name)

    @job_define ||= {}
    @jobs ||= []

    fail 'Quantum should not redefine a event' unless @job_define[key].nil?
    fail 'Quantum should not use a job twice' unless @jobs.find { |j| j.to_s == job }.nil?

    unless Object.const_defined?(job)
      job_class = Class.new(ActiveJob::Base) do
                    queue_as queue
                    def perform(*args); end
                  end

      last = job.split('::').last

      job.split('::').reduce(Object) do |m, c|

        unless m.const_defined?(c)
          if c == last
            m.const_set(c, job_class)
          else
            m.const_set(c, Module.new)
          end
        end

        m.const_get(c)
      end
    end

    @job_define[key] = Object.const_get(job)
    @jobs << @job_define[key]
  end

  def self.job_key(from, to, event)
    [from, to, event].join(':')
  end
end
