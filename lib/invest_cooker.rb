module InvestCooker
  # 目前项目的时间有两种
  # Rails 中使用 Time.zone.now
  # Invest 的非 Rails 项目使用 Application.time_zone.now
  TIME_ZONE = lambda do
    return Time.zone             if const_defined?('Rails')
    return Application.time_zone if const_defined?('Application')
    Time
  end
end

require 'mongoid'
require 'kaminari'

require 'invest_cooker/gli'
require 'invest_cooker/cbn'
require 'invest_cooker/mayi'

Kaminari::Hooks.init
