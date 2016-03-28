module InvestCooker
  module GLI
    class Validator
      VALID_CATAGORY_SET = %w(实时资讯 电子报 部委机构)

      def self.valid_column_set
        Invest::Column.pluck(:name).uniq
      end

      def self.validate_file(file_name)
        str = InvestCooker::GLI::Client.new.read(file_name)
        content_hash = Oj.load(str, symbol_keys: true)
        data = content_hash[:data] && content_hash[:data][0]
        validation = validation(data)
        {
          is_valid: validation.valid?,
          reject_reason: validation.reject_reason
        }
      end

      def self.strip_html_string(str)
        Nokogiri::HTML.fragment(str).content.utf8_strip
      end

      # 验证聚源数据的有效性
      def self.validation(data)
        fail '空数据' unless data.present?
        fail '信息来源被过滤' if
          Settings.glidata.reject_origin_websites.try(:include?, data[:XXLY].try(:to_s).try(:strip))
        fail '空标题' unless strip_html_string(data[:BT]).present?
        content = strip_html_string(data[:XXNR])
        fail '空内容' unless content.present?
        fail "内容过长:#{content.size}" if content.size > 20_000
        fail '空修改时间' unless data[:XGSJ].present?
        fail '空信息发布时间' unless data[:XXFBRQ].present?
        fail '空聚源ID' unless data[:ID].present?
        fail '空信息标签' unless data[:XXBQ].present?

        # 验证 XXBQ 格式
        catagory_column_hash = Hash.new
        data[:XXBQ].split('，').each do |catagory_column|
          catagory, column = catagory_column.split('_')
          catagory.utf8_strip!
          fail '栏目不能为空' if column.try(:utf8_strip).blank?
          catagory_column_hash[catagory] ||= []
          catagory_column_hash[catagory] << column.utf8_strip
        end
        fail '多于一个大分类' unless catagory_column_hash.keys.size == 1
        fail '大分类不符合要求' unless VALID_CATAGORY_SET.include? catagory_column_hash.keys.first
        fail '栏目不符合要求' unless valid_column_set | catagory_column_hash.values.first == valid_column_set

        fail '修改时间不可解析' unless TIME_ZONE.call.parse(data[:XGSJ]).present?
        fail '信息发布时间不可解析' unless TIME_ZONE.call.parse(data[:XXFBRQ]).present?

        # # 验证信息内容
        # content = format_content(content_to_plain_text(data[:XXNR]))
        # return false if content == "<p>\u3000\u3000广告</p>"
        # return false if content == "<p>\u3000\u3000nu</p>"

        fail '库中已有重复的聚源ID文章' if Document.where(source: :glidata, source_id: data[:ID]).present?

        Validation.new("")
      rescue RuntimeError => e
        Validation.new(e.message)
      end

      class Validation < Struct.new(:message)
        def valid_as_histroy?
          message.blank? || message == '库中已有重复的聚源ID文章'
        end

        def reject_reason_as_history
          return nil if message == '库中已有重复的聚源ID文章'
          message
        end

        def valid?
        	message.blank?
        end

        def reject_reason
          message
        end
      end
    end
  end
end
