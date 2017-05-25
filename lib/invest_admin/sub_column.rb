module InvestAdmin
  class SubColumn
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String

    belongs_to :team, index: true

    scope :team_scope, ->(team) { where(team: team) }
  end
end
