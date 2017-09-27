require 'concerns/with_temp_file'
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

    def self.upload_nokogiri(img_node, placeholder: nil)
      cdn_src = Utils::Image.upload_cdn(img_node['src'])

      if cdn_src.present? && size_of(cdn_src).to_i > 0
        img_node['src'] = cdn_src
      else
        yield "upload_nokogiri fail: #{img_node['src']}" if block_given?

        if placeholder.present?
          img_node['src'] = placeholder
        else
          img_node.unlink
        end
      end
    end

    def self.download(img_url)
      RestClient.get(img_url).body
    end

    def self.hexdigest(img_url, remote: true)
      if remote
        Digest::SHA1.hexdigest(download(img_url))
      else
        img_path = img_url
        Digest::SHA1.file(img_path).hexdigest
      end
    end

    def self.size_of(img_url)
      size = FastImage.new(img_url).content_length.to_i

      if size == 0
        size = download(img_url).size
      end

      size / 1000
    end

    def self.type_of(img_url)
      FastImage.type(img_url)
    end

    # NOTE 新的接口如果图片不存在，也会返回地址
    # 上传一个图片文件到 CDN
    # 抓取一个图片到 CDN (默认)
    def self.upload_cdn(url, remote: true, key: nil)
      Timeout.timeout 30 do
        if remote
          block = ->(cdn) { cdn.upload }
          size = size_of(url)
        else
          block = ->(cdn) { cdn.upload_file }
          size = File.open(url).size.to_i / 1000
        end

        # 4M 以上的图片不存, 2KB 以下图片不存
        return if size <= 1 || size > 4_000

        key ||= "#{hexdigest(url)}.#{type_of(url)}"
        cdn = CDNStore.new(url, key)
        block.call(cdn)
        cdn.cdn_url
      end
    rescue => error
      puts error
    end

    class CDNStore
      include WithTempFile
      attr_accessor :file_path, :target_url, :key, :cdn_url

      def initialize(path_or_url, key)
        self.file_path  = path_or_url
        self.target_url = path_or_url
        self.key = key
        self.cdn_url = "#{CDN::AliyunOSS::ENDPOINT}/#{key}"
      end

      # fetch and upload
      def upload
        data = Utils::Image.download(target_url)

        with_temp_file(data, mode: 'wb') do |path|
          CDN::AliyunOSS.instance.upload(key, path)
        end
      end

      # upload local file
      def upload_file
        CDN::AliyunOSS.instance.upload(key, file_path)
      end
    end
  end
end
