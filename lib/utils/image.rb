# Utils::Image
# 图片处理工具类
module Utils
  class Image
    # 图片地址中的编辑 ID
    def self.editor_id_for_src(src, editor_id)
      extract_editor_id(src) ||
        editor_id
    end

    # 不带编辑 ID 的图片地址
    def self.src_without_editor_id(src)
      src.to_s.split('#')[0]
    end

    # 加上了编辑 ID 的图片地址
    def self.src_with_editor_id(src, editor_id)
      "#{src_without_editor_id(src)}##{editor_id_for_src(src, editor_id)}"
    end

    def self.extract_editor_id(img_url)
      editor_id = img_url.try(:match, /#[\S]+/).try(:to_s).try(:gsub, '#', '')
      editor_id = nil if editor_id.blank?
      editor_id
    end

    def self.upload_nokogiri(img_node)
      cdn_src = Utils::Image.upload_cdn(img_node['src'])
      if cdn_src.present?
        img_node['src'] = cdn_src
      else
        img_node.unlink
      end
    end

    def self.download(img_url)
      RestClient.get(img_url).body
    end

    def self.size_of(img_url)
      FastImage.new(img_url).content_length.try(:/, 1_000) || 0
    end

    def self.type_of(img_url)
      FastImage.type(img_url)
    end

    # NOTE 新的接口如果图片不存在，也会返回地址
    def self.upload_cdn(url)
      Timeout.timeout 30 do
        size = size_of(url)
        # 4M 以上的图片不存
        return if size <= 0 || size > 4_000
        cdn = CDNStore.new(url, "#{UUID.new.generate}.#{type_of(url)}")
        cdn.upload
        cdn.cdn_url
      end
    rescue => error
      puts error
    end

    # http://developer.qiniu.com/code/v6/sdk/ruby.html#rs-fetch
    class CDNStore
      def initialize(target_url, key)
        @target_url = target_url
        @key = key
        @cdn_url = "#{BUCKET_URL}/#{key}"
      end

      def upload
        CDN::Storage.fetch BUCKET, @target_url, @key
      end

      attr_reader :cdn_url

      CDN        = Object::Qiniu
      URL        = ENV['QINIU_UPLOAD_URL'].freeze
      ACCESS_KEY = ENV['HUGO_INVEST_SERVER_QINIU_ACCESS_KEY'].freeze
      SECRET_KEY = ENV['HUGO_INVEST_SERVER_QINIU_SECRET_KEY'].freeze
      BUCKET     = ENV['QINIU_BUCKET_INVEST_IMAGE_NAME'].freeze
      BUCKET_URL = ENV['QINIU_BUCKET_INVEST_IMAGE_URL'].freeze

      CDN.establish_connection! access_key: ACCESS_KEY, secret_key: SECRET_KEY
    end
  end
end
