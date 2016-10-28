concern :LimitFrequency do

  def limit_frequency(key:, time: nil)
    return if $redis_object.get(key).present?

    $redis_object.set(key, 'processing')
    yield

  ensure
    if time.present?
      $redis_object.expire(key, time)
    else
      $redis_object.del(key)
    end
  end

  included do 
    def self.limit_frequency(method_name, key:, time: nil)
      method_with_limit_frequency = Module.new do
                                      define_method method_name do |*args|
                                        if key.respond_to?(:call)
                                          key = key.call(*args)
                                        end

                                        limit_frequency key: key, time: time do
                                          super(*args)
                                        end
                                      end
                                    end

      prepend method_with_limit_frequency
    end
  end
end
