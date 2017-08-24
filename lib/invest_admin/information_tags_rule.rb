module InvestAdmin
  class InformationTagsRule
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
    field :value, type: String
    field :target, type: String
    field :title, type: String
  end
end
