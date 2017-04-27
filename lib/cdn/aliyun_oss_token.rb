require 'aliyun/sts'

# 提供生成上传阿里云图片 Token 的逻辑
# https://github.com/aliyun/aliyun-oss-ruby-sdk/blob/master/lib/aliyun/sts/client.rb
module CDN
  class AliyunOSSToken
    include Singleton

    ACCESS_KEY = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_ACCESS_KEY'].freeze
    SECRET_KEY = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_SECRET_KEY'].freeze
    ROLE       = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_ROLE'].freeze

    def initialize
      @client = ::Aliyun::STS::Client.new access_key_id: ACCESS_KEY,
                                          access_key_secret: SECRET_KEY
    end

    def generate_token
      session_name = "invest-aliyun-oss-#{Time.zone.now.to_i}"
      @client.assume_role(ROLE, session_name)
    end
  end
end
