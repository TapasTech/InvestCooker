require 'aliyun/oss'

# 上传阿里云图片
module CDN
  class AliyunOSS
    include Singleton

    ACCESS_KEY = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_ACCESS_KEY'].freeze
    SECRET_KEY = ENV['HUGO_INVEST_SERVER_ALIYUN_OSS_SECRET_KEY'].freeze
    ENDPOINT   = ENV['ALIYUN_OSS_BUCKET_INVEST_IMAGE_URL'].freeze

    def initialize
      @client = ::Aliyun::OSS::Client.new endpoint: ENDPOINT,
                                          access_key_id: ACCESS_KEY,
                                          access_key_secret: SECRET_KEY,
                                          cname: true
    end

    def upload(file_name, file_path)
      @client.get_bucket('invest-images').put_object(file_name, file: file_path)
    end

    def destroy(file_name)
      @client.get_bucket('invest-images').delete_object(file_name)
    end
  end
end
