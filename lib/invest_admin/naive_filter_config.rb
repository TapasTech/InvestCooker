# 简单筛选项配置
module InvestAdmin
  class NaiveFilterConfig
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String
    field :value, type: String
    field :name,  type: String

    belongs_to :team, index: true
    scope :team_scope, ->(team) { where(team: team) }

    def self.to_filter
      self.all.map(&:to_filter)
    end

    def to_filter
      {title: title, value: value}
    end
  end
end
