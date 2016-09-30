concern :CacheByParams do
  included do

    def initialize(params)
    	@params = params
    end

    def cache_key
      @cache_key ||= "#{md5}/#{updated_at.to_f}"
    end

    private

    def updated_at
      Time.zone.parse('2000-01-01')
    end

    def md5
      Digest::MD5.hexdigest(Oj.dump(@params.as_json))
    end
  end
end
