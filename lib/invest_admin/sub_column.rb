module InvestAdmin
  class SubColumn
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
  end
end
