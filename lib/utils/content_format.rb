# Utils::ContentFormat 清理文章内容格式的工具模块
module Utils
  module ContentFormat
    def clear_style_of_content_summary_title
      [:content, :summary, :title].each do |field|
        format_with(field)[HTMLFormatter, :clear_style]
      end
    end

    def clear_style_of_content
      format_with(:content)[HTMLFormatter, :clear_style]
    end

    def clear_style_of_summary
      format_with(:summary)[HTMLFormatter, :clear_style]
    end

    def clear_style_of_title
      format_with(:title)[HTMLFormatter, :clear_style]
    end

    # 打股码专用
    # 调试内存泄漏
    def clear_style_of_content_2
      self.content = HTMLFormatter.format(content) { |formatter| formatter.clear_style }
    end

    def content_to_plain_text
      format_by(HTMLFormatter, :clear_content_by_dom)
      format_by(StringFormatter, *[
        :replace_br_with_slash_n,
        :replace_p_tag_with_slash_n,
        :merge_multi_connected_slash_n
      ])
      content.utf8_strip!
    end

    # 清除股码高亮
    def remove_stock_code_highlight
      format_by HTMLFormatter, :remove_stock_code_highlight
    end

    # 强制清理格式，针对入库文章
    def format_content
      format_by StringFormatter, :format_line_divide_by_slash_n
      format_by HTMLFormatter,   :ensure_dubble_chinese_blank_before_each_paragraph
    end

    # 保留合法格式，移除非法格式，针对编辑过的文章
    def soft_format_content
      format_by HTMLFormatter, :remove_blanks
    end

    def remove_space
      self.content = Nokogiri::HTML.fragment(content).inner_html
      self.content = StringFormatter.remove_space_from_line(content)
      format_by HTMLFormatter, :ensure_dubble_chinese_blank_before_each_paragraph
    end

    def ant_remove_blank
      format_by HTMLFormatter, :remove_blank_before_p_tags
    end

    def format_by(formatter_klass, *methods)
      format_with(:content)[formatter_klass, *methods]
    end

    def format_with(field_name)
      lambda do |formatter_klass, *methods|
        # 为了兼容 attr_reader, Hash like and ActiveRecord like Object.
        origin_field_value = self.try(field_name) || self.try(:[], field_name)
        field_value = formatter_klass.format(origin_field_value) { |formatter| methods.each(&formatter.method(:send)) }
        send :"#{field_name}=", field_value
      end
    end
  end
end
