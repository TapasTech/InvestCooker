require 'invest_cooker/configuration.rb'

module InvestCooker
  # 目前项目的时间有两种
  # Rails 中使用 Time.zone.now
  # Invest 的非 Rails 项目使用 Application.time_zone.now
  TIME_ZONE = lambda do
    return Time.zone             if const_defined?('Rails')
    return Application.time_zone if const_defined?('Application')
    Time
  end

  APP_ROOT = lambda do
    return Rail.root        if const_defined?('Rails')
    return Application.root if const_defined?('Application')
    ''
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end

# 开始不 require 任何 module
# 由应用的项目自行 require
