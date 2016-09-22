module Utils
  TIME_ZONE = lambda do
    return Time.zone             if const_defined?('Rails')
    return Application.time_zone if const_defined?('Application')
    Time
  end
end
