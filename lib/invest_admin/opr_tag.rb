# 运营标签
module InvestAdmin
  class OprTag
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
    field :type, type: String
  end
end
