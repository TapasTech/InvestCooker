require 'invest_cooker/base_document_parser'
require 'invest_cooker/do_not_change_gli_fields'

module InvestCooker
  module GLI
    class DocumentParser < BaseDocumentParser

      include DoNotChangeGLIFields

      attribute(:article_id) do |target:|
        next "#{id}_gli" if target == :glidata
        id.to_s
      end

      # 注意聚源的名称是 gil
      attribute(:gildata_id) do
        next source_id if source == 'glidata'
        ""
      end

      attribute(:title) do
        live? ? '直播' : title
      end

      attribute(:subtitle) do
        subtitle
      end

      attribute(:news_abstract) do
        summary
      end

      attribute(:author) do
        author
      end

      attribute(:compose_org) do
        compose_organization
      end

      attribute(:cbn_original) do
        source == 'cbn'
      end

      attribute(:content) do
        format_content
        # ---- 去掉正文中的图片 src 关联的编辑 ID
        doc = html_doc
        doc.css('img').each { |img| img['src'] = img['src'].split('#')[0] }
        self.content = doc.inner_html.gsub(/\n/, '')
        # ----
        next content unless live?
        remove_stock_code_highlight # 直播稿件去除股码高亮
        html_preview
      end

      attribute(:gmt_create) do
        (document.try(:created_at) || created_at).as_json
      end

      attribute(:gmt_modified) do
        updated_at.as_json
      end

      attribute(:news_pub_time) do
        publish_at.as_json
      end

      attribute(:keywords) do
        output_special_subjects.join(',')
      end

      # 0 发布｜更新
      # 1 下线
      # 文章栏目不包含目标栏目时，下线
      attribute(:status) do |target:|
        next 1 if state != :published
        col_codes   = columns.map { |col| col[:code] }
        doc_targets = Invest::OutputColumn.where(:code.in => col_codes).pluck(:target).uniq.as_json
        doc_targets.include?(target.to_s) ? 0 : 1
      end

      attribute(:stocks) do
        stocks_with_status
          .map { |s| {se_code: s[:code], se_name: s[:name], status: s[:status]} }
          .presence || [{se_code: "", se_name: "", status: 1}]
      end

      # 过滤掉不属于 target 的栏目
      attribute(:columns) do |target:|
        target_column_codes = Invest::OutputColumn.where(target: target).pluck(:code)
        columns_with_status
          .select { |c| target_column_codes.include?(c['code'])}
          .map    { |c| {column_code: c['code'].to_i, column_name: c['name'], status: c['status']} }
          .presence || [{column_code: "", column_name: "", status: 1}]
      end

      attribute(:origins) do
        if live?
          [{status: 1, origin_url: '', origin_date: '', origin_website: ''}]
        else
          [{status: 0, origin_url: origin_url.to_s, origin_date: origin_date.as_json, origin_website: origin_website.to_s}]
        end
      end
    end
  end
end
