module InvestCooker
  module MAYI
    class DocumentParser

      DATE_FORMAT = Settings.mayi.date_format

      def self.dump(invest_information, action)
        i = invest_information
        ensure_gli_attributes_are_valid!(i)

        json_hash =
          case action.to_sym
          when :publish
            {
              articleId:        i.id.to_s,
              title:            dump_title(i),
              subtitle:         i.subtitle,
              newsAbstract:     i.summary,
              author:           i.author,
              composeOrg:       i.compose_organization,
              content:          dump_content(i),
              gmtCreate:        dump_gmt_create(i),
              gmtModified:      i.updated_at.strftime(DATE_FORMAT),
              newsPubTime:      i.origin_date.strftime(DATE_FORMAT),
              tags:             i.tags,
              keywords:         i.keywords,
              stocks:           dump_stocks(i),
              columns:          dump_columns(i),
              origins:          dump_origins(i),
              industries:       dump_industries(i),
              concepts:         dump_concepts(i),
              regions:          dump_regions(i),
              cbnOriginal:      i.cbn_original?,
              contentHighlight: i.content_highlight,
              titleImage:       i.title_image_url
            }
          when :unpublish
            {
              articleId: i.id.to_s
            }
          else
            raise "Invalid information status."
          end

        json_str  = Oj.dump(json_hash).remove_utf_8_char_can_not_parse_to_gbk_char
        json_hash = Oj.load(json_str).as_json

        download_and_replace_image_src_gzip! json_hash if action == :publish

        json_hash
      end


      private

      def self.dump_content(invest_information)
        i = invest_information
        i.format_content

        if i.live?
          i.remove_stock_code_highlight # 直播稿件去除股码高亮
          i.html_preview
        else
          i.content
        end
      end

      # 填写聚源来的不应修改的字段，以确保我们没有修改
      def self.ensure_gli_attributes_are_valid!(invest_information)
        i = invest_information

        if i.source == 'glidata' # 如果为空，则以原文内容填写
          [:author, :compose_organization, :created_at, :origin_date].each do |attr_name|
            i.send("#{attr_name}=", i.document.send(attr_name)) if i.send(attr_name).blank?
          end
          i.source_id = i.document.source_id
        end

        if i.cbn_original? # CBN原创内容
          i.compose_organization ||= Settings.constants.compose_organization.cbn
          i.origin_url           ||= 'www.yicai.com'
          i.origin_date            = i.publish_at
          i.source_id              = i.id.to_s
        end
      end

      def self.dump_title(invest_information)
        i = invest_information
        if i.live?
          '直播'
        else
          i.title
        end
      end

      def self.dump_gmt_create(invest_information)
        i = invest_information
        if i.cbn_original?
          i.created_at
        else
          i.document.created_at
        end.strftime(DATE_FORMAT)
      end

      def self.dump_regions(invest_information)
        i_regions = invest_information.stock_regions
        i_regions.map do |i|
          {
            code: i.code,
            name: i.name
          }
        end
      end

      def self.dump_concepts(invest_information)
        i_concepts = invest_information.stock_concepts
        i_concepts.map do |i|
          {
            code: i.code,
            name: i.name
          }
        end
      end

      def self.dump_industries(invest_information)
        i_industies = invest_information.stock_industries
        i_industies.map do |i|
          {
            code: i.code,
            name: i.name
          }
        end
      end

      def self.dump_stocks(invest_information)
        i_stocks = invest_information.stocks
        i_stocks.map do |s|
          {
            code: s[:code],
            name: s[:name]
          }
        end
      end

      def self.dump_columns(invest_information)
        # 只输出蚂蚁相关栏目
        i_column_codes = invest_information.columns.map { |c| c[:code] }
        i_columns = Invest::OutputColumn.where(target: :mayi).where(:code.in => i_column_codes)
        i_columns.map do |c|
          {
            code: c.code,
            name: c.name
          }
        end
      end

      def self.dump_origins(invest_information)
        i = invest_information
        i.origin_website = '' if i.live?

        [{
          originUrl:     i.origin_url                        || "",
          originDate:    i.origin_date.strftime(DATE_FORMAT) || "",
          originWebsite: i.origin_website                    || "",
        }]
      end

      # 替换 json_hash 中的图片 url 为图片内容 base64 并压缩
      def self.download_and_replace_image_src_gzip!(json_hash)
        # 标题图片
        title_image_url = json_hash['titleImage']
        handle_img(json_hash, title_image_url) do |key|
          json_hash['titleImage'] = key
        end if title_image_url.present?

        # 内容中图片
        content_doc = Nokogiri::HTML(json_hash['content']).at('body')
        content_doc.css('img').each do |img|
          handle_img(json_hash, img['src']) do |key|
            img['src'] = key
          end
        end

        # 删除为空的图片标签
        content_doc.css('img').each do |img|
          img.unlink if img['src'].blank?
        end

        # 压缩替换内容
        content_str = content_doc.inner_html
        json_hash['content'] = Base64.strict_encode64(ActiveSupport::Gzip.compress(content_str))
      end

      def self.handle_img(json_hash, url)
        json_hash['images'] ||= []
        if Utils::Image.type_of(url).blank? || Utils::Image.size_of(url) > Settings.max_image_size
          yield ""
        else
          url_without_editor_id = url.split('#')[0]
          img_data = Utils::Image.download(url_without_editor_id)
          json_hash['images'] << Base64.strict_encode64(img_data)
          yield img_key(json_hash)
        end
      end

      def self.img_key(json_hash)
        article_id = json_hash['articleId']
        img_index = json_hash['images'].size - 1
        "#{article_id}_#{img_index}"
      end
    end
  end
end
