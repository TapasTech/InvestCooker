# frozen_string_literal: true
module Utils
  # 通过一个指针来获取真实的缓存数据
  # 数据更新时，先创建新数据，再把指针指向新数据
  # 这样可以“平滑”地更新缓存中的数据
  class SmoothCache
    TIME_ZONE = lambda do
      return Time.zone             if const_defined?('Rails')
      return Application.time_zone if const_defined?('Application')
      Time
    end.call

    extend Forwardable
    def_delegators :pointer_store, :set, :get
    def_delegators :cache_store, :write, :delete

    attr_accessor :pointer_key, :parse_block, :pointer_store, :cache_store

    def initialize(pointer_key, pointer_store: $redis_object, cache_store: Utils::Cache.redis, &parse_block)
      self.pointer_key = pointer_key
      self.parse_block = parse_block || ->(_) { _ }
      self.pointer_store = pointer_store
      self.cache_store = cache_store
    end

    def fetch
      data_key = get(pointer_key)
      cache_store.read(data_key)
    end

    def build(data, time=TIME_ZONE.now)
      new_data_key = "#{pointer_key}/#{time.to_i}"

      parsed_data = parse_block.(data)
      write(new_data_key, parsed_data)

      old_data_key = get(pointer_key)
      set(pointer_key, new_data_key)
      delete(old_data_key)
    end

    # @deprecated
    def refresh(_)
      nil
    end
  end
end
