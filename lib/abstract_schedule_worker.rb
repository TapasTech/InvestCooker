require 'sidekiq/api'

class AbstractScheduleWorker
  include Sidekiq::Worker
  QUEUE_NAME = ENV.fetch('schedule_queue')

  sidekiq_options queue: "#{QUEUE_NAME}_schedule"

  def perform
    # 清除重复的任务计划
    self.class.duplicate_schedules.each(&:delete)

    run_schedule_works if time_to_go?
    next_schedule
  end

  # 实现执行具体的任务
  def run_schedule_works
    # to implement
  end

  # 实现调用下一次任务
  def next_schedule
    if respond_to?(:next_time)
      self.class.perform_at(next_time)
    else
      # to implement
    end
  end

  # 验证是否是正确的时间
  def time_to_go?
    true
  end

  private

  # helper
  def everyday_at(now=__now__, time=2.hours)
    beginning_of_day = now.beginning_of_day

    if now >= beginning_of_day && now < (beginning_of_day + time)
      beginning_of_day + time
    else
      beginning_of_day + 1.day + time
    end
  end

  # helper
  def time_to_go_each_day?(now=__now__)
    (next_time.to_i - now.to_i - 24.hours).abs < 60
  end

  # helper
  def __now__
    InvestCooker::TIME_ZONE.call.now
  end

  # helper
  def self.duplicate_schedules
    Sidekiq::ScheduledSet.new.select { |job| job.klass == self.name && job.queue =~ /^#{QUEUE_NAME}/ }
  end

  # --- global helpers ---

  def self.inherited(child_class)
    child_class.perform_async if w.duplicate_schedules.blank?
  end
end
