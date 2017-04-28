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

    def generate_token(return_body: nil, save_key: nil)
      policy = Qiniu::Auth::PutPolicy.new(BUCKET)
      policy.return_body = return_body
      policy.save_key = save_key

      Qiniu::Auth.generate_uptoken(policy)
    end
  end
end
