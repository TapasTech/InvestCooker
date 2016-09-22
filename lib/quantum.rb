class Quantum
  def self.mail(from:, to:, event:, message:)
    Register.find_job(from, to, event).class.perform_later(*message)
  end

  class Job < Struct.new(:name, :queue);
    def class
      begin
        self.name.constantize
      rescue NameError => e
        create_job
        retry
      end
    end

  private

    def create_job
      eval code
    end

    def code
      <<-JOB
        class #{self.name} < ActiveJob::Base
          queue_as :"#{self.queue}"
          def perform(*args); end
        end
      JOB
    end
  end

  class Register
    def self.find_job(sender, receiver, event)
      job_config = Settings.quantum[sender][receiver][event]
      Job.new(job_config[:name], job_config[:queue])
    rescue NoMethodError
      raise "Quantum #{sender}:#{receiver}:#{event} does not registered."
    end
  end
end
