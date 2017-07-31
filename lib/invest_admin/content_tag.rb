module InvestAdmin
  class ContentTag
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
    field :parent, type: String
  end
end
