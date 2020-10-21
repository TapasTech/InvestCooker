require 'active_support/core_ext'
require 'concerns/with_temp_file'
require 'fastimage'

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

    def self.upload_nokogiri(
                              img_node,
                              placeholder: nil,
                              cdn_endpoint: InvestCooker.configuration.oss_endpoint,
                              oss_bucket: InvestCooker.configuration.oss_default_bucket
                            )
      origin_src = img_node['src'].to_s
      src = handle_src(origin_src)

      cdn_src = Utils::Image.upload_cdn(src, remote: true, key: nil, cdn_endpoint: cdn_endpoint, oss_bucket: oss_bucket)

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

    def self.handle_src(origin_src)
      origin_src.start_with?("//") ? "http:#{origin_src}" : origin_src
    end

    def self.download(img_url)
      RestClient::Request.execute(
        method: :get,
        url: img_url,
        timeout: 30
      ).body
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

    rescue => e
      0
    end

    def self.type_of(img_url)
      FastImage.type(img_url)
    end

    module ValidImageSize
      # 4M 以上的图片不存, 1KB 以下图片不存
      def valid_size?
        !(size <= 1 || size > 4_000)
      end
    end

    class UrlHolder
      include ValidImageSize
      attr_accessor :url, :key, :cdn

      def initialize(url:, key:)
        self.url = url
        self.key = key
      end

      def size
        @size ||= Utils::Image.size_of(url)
      end

      def key
        @key ||= "#{Utils::Image.hexdigest(url)}.#{Utils::Image.type_of(url)}"
      end

      def upload
        cdn.upload
        cdn.cdn_url
      end
    end

    class FileHolder
      include ValidImageSize
      attr_accessor :path, :key, :cdn

      def initialize(path:, key:)
        self.path = path
        self.key = key
      end

      def size
        @size ||= File.open(path).size.to_i / 1000
      end

      def upload
        cdn.upload_file
        cdn.cdn_url
      end
    end

    # NOTE 新的接口如果图片不存在，也会返回地址
    # 上传一个图片文件到 CDN
    # 抓取一个图片到 CDN (默认)
    def self.upload_cdn(
                         url,
                         remote: true,
                         key: nil,
                         cdn_endpoint: InvestCooker.configuration.oss_endpoint,
                         oss_bucket: InvestCooker.configuration.oss_default_bucket
                       )
      if remote
        holder = UrlHolder.new(url: url, key: key)
      else
        # 本地文件上传必须传入 key
        if key.nil?
          fail 'must provide a key when upload a local file.'
        end

        holder = FileHolder.new(path: url, key: key)
      end

      # 检查图片大小
      return unless holder.valid_size?

      holder.cdn =
        if OSSVolumeStore::PATH.present?
          OSSVolumeStore.new(url, holder.key)
        else
          CDNStore.new(url, holder.key, cdn_endpoint, oss_bucket)
        end

      return holder.upload
    end

    # 通过挂载 OSS volume 上传
    class OSSVolumeStore
      PATH     = ENV['OSS_VOLUME_PATH']
      BASE_URL = ENV['OSS_BASE_URL']

      require 'fileutils' if PATH.present?

      attr_accessor :file_path, :target_url, :key, :cdn_url

      def initialize(path_or_url, key)
        self.file_path  = path_or_url
        self.target_url = path_or_url
        self.key = key
        self.cdn_url = "#{BASE_URL}/#{key}"
      end

      def exists?
        File.exist?(File.expand_path(key, PATH))
      end

      # fetch and upload
      def upload
        File.open(File.expand_path(key, PATH), 'wb') do |f|
          f.puts << Utils::Image.download(target_url)
        end
      end

      # upload local file
      def upload_file
        src  = file_path
        dest = File.expand_path(key, PATH)
        FileUtils.cp(src, dest, force: true)
      end
    end

    # 通过 OSS sdk 上传
    class CDNStore
      include WithTempFile
      attr_accessor :file_path, :target_url, :key, :cdn_url, :oss_bucket

      def initialize(
                      path_or_url,
                      key,
                      cdn_endpoint=InvestCooker.configuration.oss_endpoint,
                      oss_bucket=InvestCooker.configuration.oss_default_bucket
                    )
        self.file_path  = path_or_url
        self.target_url = path_or_url
        self.key = key
        self.cdn_url = "#{cdn_endpoint}/#{key}"
        self.oss_bucket = oss_bucket
      end

      def exists?
        CDN::AliyunOSS.instance.exists?(key)
      end

      # fetch and upload
      def upload
        data = Utils::Image.download(target_url)

        with_temp_file(data, mode: 'wb') do |path|
          CDN::AliyunOSS.instance.upload(key, path, oss_bucket)
        end
      end

      # upload local file
      def upload_file
        CDN::AliyunOSS.instance.upload(key, file_path)
      end
    end
  end
end
