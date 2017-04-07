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
    set = ip_port_list.map { |ip_port| [0, ip_port] }
    redis.zadd(key % service, *set)
  end

  # 获得服务内网 ip:port
  def fetch
    member = redis.zrange(key, 0, 0).first
    redis.zincrby(key, 1, member)
    member
  end

  # 清空服务
  def clear!
    redis.del(key)
  end
end
