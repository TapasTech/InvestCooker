module InvestAdmin
  class StatisticsMonthlyGoal
    include Mongoid::Document

    field :name, type: String
    field :goal, type: Integer

    validates :name, uniqueness: true
  end
end
