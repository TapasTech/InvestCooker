concern :LimitFrequency do

  def limit_frequency(key:, time:)
    last_time = Time.zone.parse($redis_object.get(key).to_s)
    return if last_time.present? && Time.zone.now - last_time < time
    $redis_object.set(key, Time.zone.now.to_s)

    yield
  end
end
