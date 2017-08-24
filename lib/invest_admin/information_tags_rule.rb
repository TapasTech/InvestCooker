module InvestAdmin
  class InformationTagsRule
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
    field :value, type: String
    field :target, type: String

    def self.to_rule
      self.map { |r| [r.name, r.value].join(':') }.join("\n")
    end
  end
end
