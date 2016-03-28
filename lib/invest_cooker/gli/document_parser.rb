module InvestCooker
  module GLI
    class DocumentParser

      def self.dump(invest_information, target:)
        i = invest_information
        ensure_gli_attributes_are_valid!(i)

        {
          article_id:        dump_id(i, target),
          gildata_id:        dump_gildata_id(i),  # 注意聚源的缩写是 gil 不是 gli
          title:             dump_title(i),
          subtitle:          i.subtitle,
          news_abstract:     i.summary,
          author:            i.author,
          compose_org:       i.compose_organization,
          content:           dump_content(i),
          gmt_create:        dump_gmt_create(i),
          gmt_modified:      i.updated_at.as_json,
          news_pub_time:     i.origin_date.as_json,
          keywords:          i.tags && i.tags.join(","),
          status:            dump_status(i, target),
          stocks:            dump_stocks(i),
          columns:           dump_columns(i, target),
          origins:           dump_origins(i),
          cbn_original:      invest_information.cbn_original?
        }
      end

      private

      def self.dump_id(i, target)
        if target == :glidata
          "#{i.id.to_s}_gil"
        else
          i.id.to_s
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

      def self.dump_content(invest_information)
        i = invest_information
        i.format_content

        # 去掉正文中的图片 src 关联的编辑 ID
        doc = i.html_doc
        doc.css('img').each { |img| img['src'] = img['src'].split('#')[0] }
        i.content = doc.inner_html.gsub(/\n/, '')

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

      def self.dump_gmt_create(invest_information)
        i = invest_information
        if i.cbn_original?
          i.created_at
        else
          i.document.created_at
        end.as_json
      end

      def self.dump_gildata_id(invest_information)
        i = invest_information
        if i.cbn_original?
          ""
        else
          i.source_id
        end
      end

      def self.dump_status(invest_information, target)
        if should_publish_to?(invest_information, target) then 0 else 1 end
      end

      def self.should_publish_to?(invest_information, target)
        invest_information.state == :published &&
        self.dump_columns(invest_information, target).map { |c| c[:status] }.index(0).present?
      end

      def self.dump_columns(invest_information, target)
        i_columns = invest_information.columns_with_status

        target_column_codes = Invest::OutputColumn.where(target: target).pluck(:code)
        i_columns = i_columns.select { |c| target_column_codes.include?(c['code'])}

        if i_columns.size == 0
          [
            {
              column_code: "",
              column_name: "",
              status: 1
            }
          ]
        else
          i_columns.map do |c|
            {
              column_code: c['code'].to_i,
              column_name: c['name'],
              status: c['status']
            }
          end
        end
      end

      def self.dump_stocks(invest_information)
        i_stocks = invest_information.stocks_with_status
        if i_stocks.size == 0
          [
            {
              se_code: "",
              se_name: "",
              status: 1
            }
          ]
        else
          i_stocks.map do |s|
            {
              se_code: s[:code],
              se_name: s[:name],
              status: s[:status]
            }
          end
        end
      end

      def self.dump_origins(invest_information)
        i = invest_information
        i.origin_website = "" if i.live?

        [{
          origin_url: i.origin_url         || "",
          origin_date: i.origin_date       || "",
          origin_website: i.origin_website || "",
          status: 0
        }]
      end
    end
  end
end
