module Quantum
  def self.mail(from:, to:, event:, message:)
    key = job_key(from, to, event)
    job = @jobs[key]
    fail "Quantum #{key} does not registered." if job.nil?
    job.perform_later(*message)
  end

  def self.config(&block)
    class_exec(&block)
  end

  def self.tunnel(from:, to:, &block)
    @from = from
    @to = to
    class_exec(&block)
  end

  def self.event(name, queue:, job:)
    @jobs ||= {}

    unless Object.const_defined?(job)
      job_class = Class.new(ActiveJob::Base) do
        queue_as queue
        def perform(*args); end
      end

      Object.const_set(job, job_class)
    end

    key = job_key(@from, @to, name)
    @jobs[key] ||= Object.const_get(job)
  end

  def self.job_key(from, to, event)
    [from, to, event].join(':')
  end
end
