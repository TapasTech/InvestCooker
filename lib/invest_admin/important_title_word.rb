module InvestAdmin
  class ImportantTitleWord
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String
  end
end
