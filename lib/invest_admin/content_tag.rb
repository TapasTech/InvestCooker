module InvestAdmin
  class ContentTag
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
    field :parent, type: String
    field :source, type: String # 增同名，改 source，删同名，看 source
  end
end
