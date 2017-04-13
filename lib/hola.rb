require 'docker' rescue puts 'INFO: docker-api not loaded.'

# 基于 Redis 的服务注册与发现
class Hola
  attr_accessor :key, :redis, :service

  def initialize(service)
    self.service = service
    self.key = "hola/services/#{service}"
    self.redis = $redis_object
  end

  # 将服务注册到 Redis
  def add(hosts)
    hosts = hosts.select(&:present?)
    return unless hosts.present?

    hosts = hosts.map { |ip_port| [0, ip_port] }
    redis.zadd(key, *hosts)
  end

  # 获得服务内网 ip:port
  #   - 每调用一次该地址入队尾
  #   - 地址连续失效多次移除该地址
  def fetch
    host = redis.zrange(key, 0, 0).first
    return host if host.blank?

    redis.zincrby(key, 1, host)

    pod = Pod.new(key, host, redis)
    return host if pod.healthy?

    if pod.dead?
      redis.zrem(key, host)
    end

    nil
  end

  # 获得当前全部可用服务
  def list
    redis.zrange(key, 0, -1).select { |host| Pod.new(key, host, redis).healthy? }
  end

  # 清空服务
  def clear!
    redis.del(key)
  end

  class Pod
    attr_accessor :key, :redis, :host, :max_fail

    def initialize(service, host, redis)
      self.key = "#{service}/#{host}/fail"
      self.host = host
      self.redis = redis
      self.max_fail = 3
    end

    def healthy?
      RestClient.get(host)
      redis.del(key)
      true
    rescue
      redis.incr(key)
      false
    end

    def dead?
      redis.get(key).to_i > max_fail
    end
  end

  class HostInfo
    attr_accessor :service, :api_url

    def initialize(service)
      self.service = service
      self.api_url = "http://#{ip}/docker_ports"
    end

    def ip
      ENV['host_ip']
    end

    def ports
      fetch_ports_from_api ||
      ENV['ports'].to_s.split(',')
    end

    def to_set
      ports.map { |port| "#{ip}:#{port}"}
    end

    def fetch_ports_from_api
      Docker::Container.all(filters: {name: [service]}.to_json)
        .map { |d| d.info['Ports'].map { |pt| pt['PublicPort'] } }
        .flatten
    rescue
      nil
    end
  end

  class << self

    # 注册服务
    def continuing_register(service=ENV['hola_service'])
      return unless service

      Thread.new do
        while true
          begin
            set = HostInfo.new(service).to_set
            yield set if block_given?

            next unless set.present?

            Hola.new(service).add(set)
          rescue => e
            yield e.message if block_given?

            sleep 10.seconds
            next
          end

          sleep 1.minute
        end
      end
    end

    # 初始化可用连接到内存
    # 开新线程定时更新可用连接
    def init(service)
      $__hola_sync__ ||= {}
      $__hola_host__ ||= {}

      $__hola_sync__[service] ||= Thread.new do
        while true
          begin
            $__hola_host__[service] = Hola.new(service).fetch
          rescue
            sleep 10.seconds
            next
          end

          sleep 10.seconds
        end
      end
    end

    def fetch(service)
      $__hola_host__[service]
    end
  end
end
