module InvestAdmin
  class ImportantOriginWebsite
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String

    belongs_to :team
  end
end
