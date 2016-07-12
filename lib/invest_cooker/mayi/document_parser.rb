require 'invest_cooker/base_document_parser'
require 'invest_cooker/do_not_change_gli_fields'

module InvestCooker
  module MAYI
    class DocumentParser < BaseDocumentParser

      class << self

        # 下载、编码 json_hash 中的图片并插入 json_hash['images']
        # 替换 json_hash 中的图片 url 为 json_hash['images'] 中的 index
        # 压缩 json_hash['content'] 并 base64

        # 标题图片
        def handle_title_image(json_hash)
          json_hash['titleImage'] = handle_image(json_hash, json_hash['titleImage'])
          json_hash
        end

        # 内容中图片
        def handle_content_images(json_hash, is_live)
          unless is_live
            content_doc = Nokogiri::HTML(json_hash['content']).at('body')
            content_doc.css('img').map { |img| img['src'] = handle_image(json_hash, img['src']); img }
                                  .select { |img| img['src'].blank? }
                                  .each(&:unlink)
            json_hash['content'] = content_doc.inner_html
          end

          json_hash
        end

        # 压缩替换内容
        def gzip_content(json_hash)
          json_hash['content'] = Base64.strict_encode64(ActiveSupport::Gzip.compress(json_hash['content']))
          json_hash
        end

        private

        def valid_image_url?(url)
          url.present? &&
          Utils::Image.type_of(url).present? &&
          Utils::Image.size_of(url) <= Settings.max_image_size
        end

        # @return image_key
        def handle_image(json_hash, url)
          json_hash['images'] ||= []
          return '' unless valid_image_url?(url)
          json_hash['images'] << generate_image_data(url)
          [json_hash['articleId'], json_hash['images'].size - 1].join('_')
        end

        def generate_image_data(url)
          Base64.strict_encode64(Utils::Image.download(url.split('#')[0]))
        end
      end

      # 下线文章只要 :articleId
      skip_dump do |action|
        {articleId: id.to_s}.as_json if action.to_sym == :unpublish
      end

      include DoNotChangeGLIFields

      after_dump { |result| Oj.dump(result).remove_utf_8_char_can_not_parse_to_gbk_char }
      after_dump { |result| Oj.load(result).as_json }
      after_dump { |result| InvestCooker::MAYI::DocumentParser.handle_title_image(result) }
      after_dump { |result| InvestCooker::MAYI::DocumentParser.handle_content_images(result, live?) }
      after_dump { |result| InvestCooker::MAYI::DocumentParser.gzip_content(result) }

      attribute(:articleId) do
        id.to_s
      end

      attribute(:title) do
        live? ? '直播' : title
      end

      attribute(:subtitle) do
        subtitle
      end

      attribute(:newsAbstract) do
        summary
      end

      attribute(:author) do
        author
      end

      attribute(:composeOrg) do
        compose_organization
      end

      attribute(:gmtCreate) do
        (document.try(:created_at) || created_at).strftime(Settings.mayi.date_format)
      end

      attribute(:gmtModified) do
        updated_at.strftime(Settings.mayi.date_format)
      end

      attribute(:newsPubTime) do
        origin_date.strftime(Settings.mayi.date_format)
      end

      attribute(:tags) do
        output_special_subjects
      end

      attribute(:keywords) do
        keywords
      end

      attribute(:stocks) do
        stocks.map { |s| {code: s[:code], name: s[:name]} }
      end

      # 只输出蚂蚁相关栏目
      attribute(:columns) do
        Invest::OutputColumn
          .where(target: :mayi)
          .where(:code.in => columns.map { |c| c[:code] })
          .map { |c| {code: c.code, name: c.name} }
      end

      attribute(:origins) do
        if live?
          [{status: 1, originUrl: '', originDate: '', originWebsite: ''}]
        else
          if origin_url.present?
            [{status: 0, originUrl: origin_url.to_s, originDate: origin_date.as_json, originWebsite: origin_website.to_s}]
          else
            if source == 'cbn'
              [{status: 0, originUrl: 'http://www.dtcj.com/', originDate: origin_date.as_json, originWebsite: origin_website.to_s}]
            else
              [{status: 0, originUrl: 'NoUrl', originDate: origin_date.as_json, originWebsite: origin_website.to_s}]
            end
          end
        end
      end

      attribute(:industries) do
        stock_industries.map { |it| {code: it.code, name: it.name} }
      end

      attribute(:concepts) do
        stock_concepts.map { |it| {code: it.code, name: it.name} }
      end

      attribute(:regions) do
        stock_regions.map { |it| {code: it.code, name: it.name} }
      end

      attribute(:cbnOriginal) do
        source == 'cbn'
      end

      attribute(:contentHighlight) do
        content_highlight
      end

      attribute(:titleImage) do
        title_image_url
      end

      attribute(:content) do
        format_content
        # 2016-07-11 蚂蚁直播只传文本
        if live?
          preview
        else
          content
        end
      end
    end
  end
end
