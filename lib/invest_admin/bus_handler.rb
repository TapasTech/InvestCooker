# 用来记录当前使用的 CDN
module InvestAdmin
  class BusHandler
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name,  type: String
    field :value, type: String
  end
end
