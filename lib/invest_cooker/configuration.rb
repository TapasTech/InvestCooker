module InvestCooker
  class Configuration
    attr_accessor :oss_endpoint,
                  :oss_private_endpoint,
                  :oss_access_key_id,
                  :oss_access_key_secret,
                  :oss_default_bucket,
                  :oss_default_private_bucket,
                  :oss_open_timeout,
                  :oss_read_timeout

    def initialize
      # default configurations, ENV variable compatible with this gem old version
      @oss_endpoint = ENV['ALIYUN_OSS_BUCKET_INVEST_IMAGE_URL'].freeze || 'http://invest-images.oss-cn-shanghai.aliyuncs.com'
      @oss_private_endpoint = ENV['ALIYUN_OSS_PRIVATE_ENDPOINT'] || @oss_endpoint&.sub('http://invest-images', 'https://invest-private')
      @oss_access_key_id = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_ACCESS_KEY'].freeze
      @oss_access_key_secret = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_SECRET_KEY'].freeze
      @oss_default_bucket = ENV['ALIYUN_OSS_DEFAULT_BUCKET'] || 'invest-images'
      @oss_default_private_bucket = ENV['ALIYUN_OSS_DEFAULT_BUCKET'].freeze || 'invest-private'
      @oss_open_timeout = 5
      @oss_read_timeout = 5
    end
  end
end
