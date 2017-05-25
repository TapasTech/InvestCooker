module InvestAdmin
  class SubColumn
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String
  end
end
