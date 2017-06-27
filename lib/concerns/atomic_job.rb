module AtomicJob
  extend ActiveSupport::Concern

  included do
    prepend AtomicPerform

    before_perform { config_lock }

    self.lock_script = <<-LUA
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      else
        return 0
      end
    LUA

    self.lock_script_sha = Digest::SHA1.hexdigest(lock_script)
    self.redis_version = $redis_object.info['redis_version']
  end

  module AtomicPerform
    def perform(*args)
      sleep 0.001 until aquire_lock
      super(*args)
    ensure
      release_lock
    end
  end

  module ClassMethods
    attr_accessor :atomic_lock, :lock_script_sha, :lock_script, :redis_version
  end

  def config_lock
    @lock_script = self.class.lock_script
    @lock_script_sha = self.class.lock_script_sha
    @redis_version = self.class.redis_version

    @lock_key = if (key = self.class.atomic_lock[:key]).respond_to?(:call)
      instance_exec(&key)
    else
      key.to_s
    end

    @lock_timeout = if (timeout = self.class.atomic_lock[:timeout]).respond_to?(:call)
      instance_exec(&:timeout)
    else
      timeout.to_i
    end

    @lock_value = SecureRandom.hex(25)
  end

  def aquire_lock
    $redis_object.set(@lock_key, @lock_value, nx: true, ex: @lock_timeout)
  end

  def release_lock
    if @redis_version.to_i < 3
      $redis_object.del(@lock_key)
    else
      begin
        $redis_object.evalsha @lock_script_sha, keys: [@lock_key], argv: [@lock_value]
      rescue Redis::CommandError
        $redis_object.eval @lock_script, keys: [@lock_key], argv: [@lock_value]
      end
    end
  end
end
