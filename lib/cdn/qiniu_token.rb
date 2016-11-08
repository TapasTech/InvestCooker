module CDN
  class QiniuToken
    include Singleton

    ACCESS_KEY = ENV['HUGO_INVEST_SERVER_QINIU_ACCESS_KEY'].freeze
    SECRET_KEY = ENV['HUGO_INVEST_SERVER_QINIU_SECRET_KEY'].freeze
    BUCKET     = ENV['QINIU_BUCKET_INVEST_IMAGE_NAME'].freeze

    def initialize
      Qiniu.establish_connection! access_key: ACCESS_KEY,
                                  secret_key: SECRET_KEY
    end

    def generate_token
      Qiniu::Auth.generate_uptoken(Qiniu::Auth::PutPolicy.new(BUCKET))
    end
  end
end
