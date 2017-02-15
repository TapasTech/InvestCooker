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
      if cdn_src.present? && size_of(cdn_src).to_i > 0
        img_node['src'] = cdn_src
      else
        yield "upload_nokogiri fail: #{img_node['src']}" if block_given?
        img_node.unlink
      end
    end

    def self.download(img_url)
      RestClient.get(img_url).body
    end

    def self.size_of(img_url)
      FastImage.new(img_url).content_length.to_i / 1000
    end

    def self.type_of(img_url)
      FastImage.type(img_url)
    end

    # NOTE 新的接口如果图片不存在，也会返回地址
    # 上传一个图片文件到 CDN
    # 抓取一个图片到 CDN (默认)
    def self.upload_cdn(url, remote: true)
      Timeout.timeout 30 do
        if remote
          block = ->(cdn) { cdn.upload }
          size = size_of(url)
        else
          block = ->(cdn) { cdn.upload_file }
          size = File.open(url).size.to_i / 1000
        end

        # 4M 以上的图片不存
        return if size <= 0 || size > 4_000

        cdn = CDNStore.new(url, "#{UUID.new.generate}.#{type_of(url)}")
        block.call(cdn)
        cdn.cdn_url
      end
    rescue => error
      puts error
    end

    # http://developer.qiniu.com/code/v6/sdk/ruby.html#rs-fetch
    class CDNStore
      def initialize(path_or_url, key)
        @file_path  = path_or_url
        @target_url = path_or_url
        @key = key
        @cdn_url = "#{BUCKET_URL}/#{key}"
      end

      def upload
        CDN::Storage.fetch BUCKET, @target_url, @key
      end

      def upload_file
        put_policy = CDN::Auth::PutPolicy.new(
          BUCKET, # 存储空间
          @key,   # 指定上传的资源名，如果传入 nil，就表示不指定资源名，将使用默认的资源名
          300     # token 过期时间，默认为 3600 秒，即 1 小时
        )

        uptoken = CDN::Auth.generate_uptoken(put_policy)

        CDN::Storage.upload_with_token_2(
           uptoken,
           @file_path,
           @key,
           nil, # 可以接受一个 Hash 作为自定义变量，请参照 http://developer.qiniu.com/article/kodo/kodo-developer/up/vars.html#xvar
           bucket: BUCKET
        )
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
