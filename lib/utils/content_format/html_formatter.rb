# Utils::ContentFormat::HTMLFormatter 格式化内容的 HTML
module Utils
  module ContentFormat
    class HTMLFormatter < BasicFormatter
      attr_accessor :valid_tags, :options

      def initialize(content, options={})
        self.content = content
        self.valid_tags = options[:valid_tags] || VALID_TAGS
        self.options = options
      end

      def as_html?
        options[:html] == true
      end

      def formatted_content
        if as_html?
          doc.inner_html
        else
          remove_markup(doc.inner_html)
        end.presence || ''
      end

      def replace_tags
        from, to = options[:from], options[:to]
        return if from.nil? || to.nil?

        wrap, unwrap = options[:wrap], options[:unwrap]

        doc.css(from).wrap(wrap) unless wrap.nil?

        doc.css(from).each do |node|
          node.name = to
          node.replace(node.children) unless unwrap.nil?
        end
      end

      def clear_style
        doc.css('style').unlink
        @doc = Nokogiri::HTML.fragment(Sanitize.fragment(formatted_content, valid_tags))
      end

      ESCAPE_SEQUENCES = {
        '&amp;' => '&',
        '&lt;' => '<',
        '&gt;' => '>',
        '&quot;' => '"',
        '&apos;' => "'"
      }

      # 替换被 Sanitize 转换的 character entity
      # 删除换行符
      def remove_markup(html_str)
        ESCAPE_SEQUENCES.each do |esc_seq, ascii_seq|
          html_str = html_str.gsub(esc_seq, ascii_seq.chr)
        end

        html_str
      end

      # 清除正文中股码信息
      def remove_stock_code_suffix
        stock_code_highlights.each { |node| node.replace node.content.gsub(/（(\w+\.[FHKOSUZ]{2}；?)+）/, '') }
      end

      # 清除股码高亮
      def remove_stock_code_highlight
        stock_code_highlights.each(&ClassMethods.method(:replace_node_with_content))
      end

      def clear_content_by_dom
        ClassMethods.iterate_doc(doc, &ClassMethods.method(:clear_one_node_by_dom))
      end

      # doc 的子元素必然为 p 的列表，且 p 中不可能嵌套有 p
      def ensure_dubble_chinese_blank_before_each_paragraph
        p_tags.search('br').unlink
        p_tags.each(&ClassMethods.method(:remove_blank_char))
        p_tags.search('strong').each(&ClassMethods.method(:remove_blank_node))
        p_tags.each(&ClassMethods.method(:remove_blank_node))
        p_tags.each(&ClassMethods.method(:add_two_chinese_space_before_paragraph))
      end

      def remove_blanks
        p_tags.search('br').unlink
        p_tags.search('strong').each(&ClassMethods.method(:remove_blank_node))
        p_tags.each(&ClassMethods.method(:remove_blank_node))
      end

      def remove_blank_before_p_tags
        p_tags.each(&ClassMethods.method(:remove_blank_before_paragraph))
      end

      private

      QUIZ_VALID_TAGS = {
        elements: %w(p span),
        attributes: {
          'span' => %w(style class url),
          'p'    => %w(style)
        }
      }

      VALID_TAGS = {
        elements: %w(a img span p strong table thead tbody tr td h4 blockquote),
        attributes: {
          'a'      => %w(style href-id target title),
          'img'    => %w(style src alt),
          'span'   => %w(style class url title),
          'p'      => %w(style),
          'strong' => %w(style),
          'h4'     => %w(style),
          'blockquote' => %w(style)
        }
      }

      def stock_code_highlights
        @stock_code_highlights ||= doc.css('.hugo-stock-code')
      end

      def p_tags
        @p_tags ||= doc.css('p')
      end

      def doc
        # Use fragment [http://www.questionsandanswers.info/questions/140419/how-to-prevent-nokogiri-from-adding-doctype-tags]
        @doc ||= Nokogiri::HTML.fragment(content)
      end

      # ClassMethods HTMLFormatter 的工具方法集合
      module ClassMethods
        REMOVE_BLANK_CHAR = {
          formatter: lambda do |type|
            lambda do |text_nodes|
              REMOVE_BLANK_CHAR[type][:transform][text_nodes].each do |text_node|
                formatted_text = text_node.content.gsub(REMOVE_BLANK_CHAR[type][:regexp], '')
                if formatted_text.blank?
                  text_node.unlink
                else
                  text_node.content = formatted_text
                  break
                end
              end
            end
          end,
          head: {
            regexp: /\A[\u3000\u00a0\ \t]+/,
            transform: -> (text_nodes) { text_nodes }
          },
          tail: {
            regexp: /[\u3000\u00a0\ \t]+\z/,
            transform: -> (text_nodes) { text_nodes.reverse }
          }
        }

        def self.remove_blank_char(p_tag)
          text_nodes = p_tag.search('text()')
          formatter = REMOVE_BLANK_CHAR[:formatter]
          formatter[:head][text_nodes]
          formatter[:tail][text_nodes]
        end

        def self.clear_one_node_by_dom(node)
          %w(
            clear_class
            remove_useless_tags
            remove_blank_node
            replace_all_hyper_link_with_span_tag
            replace_all_new_line_wrap_tag_with_p_tag
          ).each do |method|
            ClassMethods.send method, node
          end
        end

        def self.add_two_chinese_space_before_paragraph(p_tag)
          # 这里如果开头是图片标签，则不加空格
          return if start_with_a_img_tag?(p_tag)
          p_tag.inner_html = "\u3000\u3000#{p_tag.inner_html}"
        end

        def self.remove_blank_before_paragraph(p_tag)
          p_tag.inner_html = p_tag.inner_html.utf8_strip
        end

        def self.start_with_a_img_tag?(p_tag)
          p_tag.children.first.try(:name) == 'img'
        end

        # 移除空节点
        def self.remove_blank_node(node)
          lambda do |node_name|
            return if node_name == 'img'
            # return remove_blank_br_node(node) if node_name == 'br'
            # remove_blank_none_br_node(node)
          end[node.name]
        end

        def self.remove_blank_br_node(node)
          node.unlink if node.parent.content.blank?
          nil
        end

        def self.remove_blank_none_br_node(node)
          node.unlink if node.content.blank? && node.children.count == 0
          nil
        end

        # 遍历文档
        def self.iterate_doc(node, &block)
          return if node.blank?
          node_children = node.children
          node_children.each do |node_|
            iterate_doc(node_, &block)
          end if node_children.count > 0
          block.call(node)
        end

        # h4 作为段落小标题存在不要替换
        NEW_LINE_WRAP_TAGS = %w(div pre h1 h2 h3 h5 h6)
        def self.replace_all_new_line_wrap_tag_with_p_tag(node)
          node.name = 'p' if NEW_LINE_WRAP_TAGS.include? node.name
        end

        # 移除超链接
        def self.replace_all_hyper_link_with_span_tag(node)
          node.name = 'span' if node.name == 'a'
        end

        USELESS_TAGS = %w(script input style textarea iframe)
        def self.remove_useless_tags(node)
          node.xpath('.//comment()').each(&:unlink)
          USELESS_TAGS.each do |tag_name|
            node.css(tag_name).unlink
          end
        end

        # 清除HTML文档中的所有样式属性
        def self.clear_class(node)
          node.attributes.keys.each do |attribute|
            node.remove_attribute attribute unless
              node.name == 'img' && %w(src alt).include?(attribute)
          end
        end

        def self.replace_node_with_content(node)
          node.replace node.content
        end
      end
    end
  end
end
