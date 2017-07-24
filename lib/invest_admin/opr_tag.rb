# 运营标签
module InvestAdmin
  class OprTag
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String
    field :type, type: String

    belongs_to :team, index: true

    scope :team_scope, ->(team) { where(team: team) }
  end
end
