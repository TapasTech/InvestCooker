module InvestAdmin
  class ForbiddenWord
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String
  end
end
