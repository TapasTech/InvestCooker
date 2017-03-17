module InvestAdmin
  class MAYILiveOriginWebsiteOutputBlackList
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String

    belongs_to :team, index: true
  end
end
