module Utils
  class Cache
    def self.redis
      @redis ||= ActiveSupport::Cache::RedisStore.new($redis_cache.client.options)
    end

    def self.redis_batch_delete(key)
      keys = $redis_cache.keys(key)
      $redis_cache.del(keys) if keys.present?
    end
  end
end
