module InvestAdmin
  class StatisticsMonthlyGoal
    include Mongoid::Document

    field :name, type: String
    field :daily_average_goal, type: Integer

    validates :name, uniqueness: true

    belongs_to :team, index: true

    def goal
      @goal ||= daily_average_goal * Time.days_in_month(Time.zone.now.month)
    end
  end
end
