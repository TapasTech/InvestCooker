module InvestAdmin
  class ForbiddenOriginWebsite
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String

    belongs_to :team

    index(team_id: 1, name: 1)
  end
end
