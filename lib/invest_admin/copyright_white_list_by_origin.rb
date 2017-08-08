# 记录来源下撰写机构版权白名单
module InvestAdmin
  class CopyrightWhiteListByOrigin
    include Mongoid::Document
    include Mongoid::Timestamps

    field :origin_website, type: String
    field :compose_organizations, type: Array, default: -> { [] }

    belongs_to :team, index: true
  end
end
