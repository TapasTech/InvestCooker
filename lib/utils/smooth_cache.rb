module Utils
  class SmoothCache

    def initialize(key, &parse)
    	@key   = key
      @parse = parse
    end

    def fetch
      Utils::Cache.redis.read key
    end

    def build(data)
      "#{@key}/#{Application.time_zone.now.to_i}".tap do |new_key|
        cache new_key, data
      end
    end

    def refresh(new_key)
      key.tap do |old_key|
        $redis_object.set(@key, new_key)
        Utils::Cache.redis.delete(old_key)
      end
    end

    private

    def key
      $redis_object.get(@key)
    end

    def cache(key, data)
      Utils::Cache.redis.write key, @parse.(data)
    end
  end
end
