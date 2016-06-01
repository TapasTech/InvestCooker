require 'open-uri'
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
      src.split('#')[0]
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

    def self.upload_cdn(url)
      Timeout.timeout 30 do
        return if size_of(url) > 4_000 # 4M 以上的图片不存
        qiniu = Qiniu.new(open(url), "#{UUID.new.generate}.#{type_of(url)}")
        Chain(qiniu).upload._.cdn_url
      end
    rescue => error
      puts error
    end

    # Qiniu
    # 上传七牛
    Qiniu = Struct.new(:image_file, :key) do
      def upload
        RestClient.post config.upload_url,
                        token: config.uptoken.call,
                        file:  image_file,
                        key:   key
      end

      def cdn_url
        @cdn_url ||= "#{config.buckets.invest.url}/#{key}"
      end

      private

      def config
        @config ||= Settings.qiniu
      end
    end
  end
end
