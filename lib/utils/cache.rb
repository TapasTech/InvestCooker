module Utils
  class Cache
    def self.redis
      @redis ||= ActiveSupport::Cache::RedisStore.new(client_info.options)
    end

    # REF: https://github.com/redis/redis-rb/blob/master/CHANGELOG.md#40
    def self.client_info
      @client_info ||=
        if Redis::VERSION.split('.').first.to_i > 3
          $redis_cache._client
        else
          $redis_cache.client
        end
    end

    def self.redis_batch_delete(key)
      keys = $redis_cache.keys(key)
      $redis_cache.del(keys) if keys.present?
    end
  end
end
