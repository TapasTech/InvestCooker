require 'invest_cooker/base_document_parser'

module InvestCooker
  module MAYI
    class DocumentParser < BaseDocumentParser

      class << self

        # 下载、编码 json_hash 中的图片并插入 json_hash['images']
        # 替换 json_hash 中的图片 url 为 json_hash['images'] 中的 index
        # 压缩 json_hash['content'] 并 base64
        def download_and_replace_image_src_gzip!(json_hash)
          # 标题图片
          json_hash['titleImage'] = handle_image(json_hash, json_hash['titleImage'])
          # 内容中图片
          content_doc = Nokogiri::HTML(json_hash['content']).at('body')
          content_doc.css('img')
            .map    { |img| img['src'] = handle_image(json_hash, img['src']); img }
            .select { |img| img['src'].blank? }.each(&:unlink)
          # 压缩替换内容
          json_hash['content'] = Base64.strict_encode64(ActiveSupport::Gzip.compress(content_doc.inner_html))
          # 返回结果
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

      # 填写聚源来的不应修改的字段，以确保我们没有修改
      before_dump do
        case source
        when 'glidata'
          self.source_id = document.source_id
          [:author, :compose_organization, :created_at, :origin_date]
            .select { |attr_name| self[attr_name].blank? }
            .each   { |attr_name| self[attr_name] = document[attr_name] }

        when 'cbn'
          self.compose_organization ||= Settings.constants.compose_organization.cbn
          self.origin_url           ||= 'www.yicai.com'
          self.origin_date            = publish_at
          self.source_id              = id.to_s
        end
      end

      after_dump { |result| Oj.dump(result).remove_utf_8_char_can_not_parse_to_gbk_char }
      after_dump { |result| Oj.load(result).as_json }
      after_dump { |result| InvestCooker::MAYI::DocumentParser.download_and_replace_image_src_gzip!(result) }

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
        self.origin_website = '' if live?
        [{originUrl: origin_url.to_s, originDate: origin_date.to_s, originWebsite: origin_website.to_s}]
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
        next content unless live?
        remove_stock_code_highlight # 直播稿件去除股码高亮
        html_preview
      end
    end
  end
end
