# 简单筛选项配置
module InvestAdmin
  class NaiveFilterConfig
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :title, type: String
    field :value, type: String
    field :name,  type: String

    def self.to_filter
      self.all.map(&:to_filter)
    end

    def to_filter
      {title: title, value: value}
    end
  end
end
