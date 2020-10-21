# Utils::Html
# html文本处理工具类
module Utils
  class Html
    class << self
      def replace_content_images_with_cdn(
                                           html_content,
                                           cdn_endpoint: configuration.oss_endpoint,
                                           oss_bucket: configuration.oss_default_bucket
                                         )
        nokogiri_node_set = Nokogiri::HTML.fragment(html_content)
        nokogiri_node_set&.css('img')
           &.reject { |img| img['src'].blank? }
           &.reject { |img| img['style'].to_s.sub(' ', '').match? /display:none/ }
           &.each   { |img| img.attribute_nodes.reject { |n| n.name == 'src'}.each(&:unlink) }
           &.each   { |img| Image.upload_nokogiri(img, cdn_endpoint: cdn_endpoint, oss_bucket: oss_bucket) }

        nokogiri_node_set&.inner_html || ''
      end

      def configuration
        InvestCooker.configuration
      end
    end
  end
end
