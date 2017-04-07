# 基于 Redis 的服务注册与发现
class Hola

  class << self

    def self.key_template
      'hola/services/%s'
    end

    # 将服务注册到 Redis
    def register(service, ip_port_list)
      key = key_template % service
      set = ip_port_list.map { |ip_port| [0, ip_port] }
      $redis_object.zadd(key % service, *set)
    end

    # 获得服务内网 ip:port
    def fetch(service)
      key = key_template % service
      member = $redis_object.zrange(key, 0, 0).first
      $redis_object.zincrby(key, 1, member)
      member
    end
  end
end
