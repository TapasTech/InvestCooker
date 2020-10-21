require 'aliyun/oss'

# 上传阿里云图片
module CDN
  class AliyunOSS
    include Singleton

    def initialize
      oss_config = {
        endpoint: configuration.oss_endpoint,
        access_key_id: configuration.oss_access_key_id,
        access_key_secret: configuration.oss_access_key_secret,
        open_timeout: configuration.oss_open_timeout,
        read_timeout: configuration.oss_read_timeout,
        cname: true
      }

      @client = ::Aliyun::OSS::Client.new(oss_config)
      @private_client = ::Aliyun::OSS::Client.new(oss_config.merge(endpoint: configuration.oss_private_endpoint))
    end

    def exists?(file_name, bucket=configuration.oss_default_bucket)
      @client.get_bucket(bucket).object_exists?(file_name)
    end

    def upload(file_name, file_path, bucket=configuration.oss_default_bucket)
      @client.get_bucket(bucket).put_object(file_name, file: file_path)
    end

    def destroy(file_name, bucket=configuration.oss_default_bucket)
      @client.get_bucket(bucket).delete_object(file_name)
    end

    def signed_url(file_name, bucket=configuration.oss_default_bucket)
      @private_client.get_bucket(bucket).object_url(file_name)
    end

    def configuration
      InvestCooker.configuration
    end
  end
end
