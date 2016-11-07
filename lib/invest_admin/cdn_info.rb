# 用来记录当前使用的 CDN
module InvestAdmin
  class CDNInfo
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String
    validates :name, inclusion: {in: %w(qiniu aliyun_oss), message: 'CDN %{value} is not supported.'}
  end
end
