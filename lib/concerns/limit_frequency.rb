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
end
