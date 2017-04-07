# 基于 Redis 的服务注册与发现
class Hola
  attr_accessor :key, :service, :redis

  def initialize(service)
  	self.service = service
    self.key = "hola/services/#{service}"
    self.redis = $redis_object
  end

  # 将服务注册到 Redis
  def add(ip_port_list)
    list = ip_port_list.select { |ip_port| ip_port.present? }
    return unless list.present?

    set = list.map { |ip_port| [0, ip_port] }
    redis.zadd(key, *set)
  end

  # 获得服务内网 ip:port
  def fetch
    host = redis.zrange(key, 0, 0).first
    return unless host.present?
    RestClient.get(host) # health check
    redis.zincrby(key, 1, host)
    host
  rescue
    redis.zrem(key, host)
    retry
  end

  # 清空服务
  def clear!
    redis.del(key)
  end

  class << self
    def register(service)
      set = ports.map { |port| "#{ip}:#{port}" }
      return unless set.present?

      Hola.new(service).add(set)
    end

    def ip
      ENV['host_ip']
    end

    def ports
      ENV['ports'].to_s.split(',')
    end
  end
end
