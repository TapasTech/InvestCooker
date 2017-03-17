# 记录某一来源的稿件只接收来自某一类撰写机构的稿件
module InvestAdmin
  class AcceptedOrganizationsByOrigin
    include Mongoid::Document
    include Mongoid::Timestamps

    field :origin_website, type: String
    field :compose_organizations, type: Array, default: -> { [] }

    belongs_to :team, index: true
  end
end
