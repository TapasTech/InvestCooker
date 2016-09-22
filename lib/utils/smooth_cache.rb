module Utils
  class SmoothCache
    TIME_ZONE = lambda do
      return Time.zone             if const_defined?('Rails')
      return Application.time_zone if const_defined?('Application')
      Time
    end.call

    def initialize(key, &parse)
      @key = key
      @parse = parse
    end

    def fetch
      Utils::Cache.redis.read key
    end

    def build(data)
      "#{@key}/#{TIME_ZONE.now.to_i}".tap do |new_key|
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
      data = @parse.call(data) unless @parse.nil?
      Utils::Cache.redis.write key, data
    end
  end
end
