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

    if pod.dead? && list.size < 2
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
      self.max_fail = 10
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

  class << self
    def register(service)
      set = ports.map { |port| "#{ip}:#{port}" }
      return unless set.present?

      Hola.new(service).add(set)
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

          sleep 1.minute
        end
      end
    end

    def fetch(service)
      $__hola_host__[service]
    end

    def ip
      ENV['host_ip']
    end

    def ports
      ENV['ports'].to_s.split(',')
    end
  end
end
