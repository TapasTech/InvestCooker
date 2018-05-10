require 'aliyun/oss'

# 上传阿里云图片
module CDN
  class AliyunOSS
    include Singleton

    ACCESS_KEY = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_ACCESS_KEY'].freeze
    SECRET_KEY = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_SECRET_KEY'].freeze
    ENDPOINT   = ENV['ALIYUN_OSS_BUCKET_INVEST_IMAGE_URL'].freeze

    PRIVATE_ENDPOINT = ENDPOINT.sub('http://invest-images', 'https://invest-private')
    CLIENT_CONFIG = {
      access_key_id: ACCESS_KEY,
      access_key_secret: SECRET_KEY,
      cname: true,
      open_timeout: 5,
      read_timeout: 5
    }

    BUCKET_NAME = 'invest-images'
    PRIVATE_BUCKET_NAME = 'invest-private'

    def initialize
      @client = ::Aliyun::OSS::Client.new(CLIENT_CONFIG.merge(endpoint: ENDPOINT))
      @private_client = ::Aliyun::OSS::Client.new(CLIENT_CONFIG.merge(endpoint: PRIVATE_ENDPOINT))
    end

    def exists?(file_name)
      @client.get_bucket(BUCKET_NAME).object_exists?(file_name)
    end

    def upload(file_name, file_path)
      @client.get_bucket(BUCKET_NAME).put_object(file_name, file: file_path)
    end

    def destroy(file_name)
      @client.get_bucket(BUCKET_NAME).delete_object(file_name)
    end

    def signed_url(file_name)
      @private_client.get_bucket(PRIVATE_BUCKET_NAME).object_url(file_name)
    end
  end
end
