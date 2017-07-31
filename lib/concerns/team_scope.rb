concern :TeamScope do
  included do
    belongs_to :team, index: true
    
    scope :team_scope, ->(team) { where(team: team) }
  end
end
