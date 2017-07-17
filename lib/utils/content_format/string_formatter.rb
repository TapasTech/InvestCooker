# Utils::ContentFormat::StringFormatter 格式化内容的字符串
module Utils
  module ContentFormat
    class StringFormatter < BasicFormatter
      def merge_multi_connected_slash_n
        content.gsub!(/\n+/, "\n")
      end

      def replace_br_with_slash_n
        content.gsub!(%r{<br>|<br\/>|<\/br>}i, "\n")
      end

      def format_line_divide_by_slash_n
        return if (content =~ /\n/).blank? && content =~ /<p>/i

        self.content =
          content.split("\n").map do |line|
            "<p>\u3000\u3000#{Utils::ContentFormat::StringFormatter.remove_space_from_line(line)}</p>"
          end.join
      end

      def replace_p_tag_with_slash_n
        content.gsub!(/<p>/i, '')
        content.gsub!(%r{<\/p>}i, "\n")
      end

      def formatted_content
        content
      end

      def self.remove_space_from_line(line)
        rexp = /(?<![a-zA-Z\p{Punct}])[\ \t\u00A0\u3000]+(?![a-zA-Z\p{Punct}])/

        # 移除部分中文标点后空格 。 ；  ， ： “ ”（ ） 、 ？ 《 》
        rexp_2 = /(?<=[\u3002\uff1b\uff0c\uff1a\u201c\u201d\uff08\uff09\u3001\uff1f\u300a\u300b])[\ \t\u00A0\u3000]+/

        # 移除数字和 % ％ 之间的空格
        rexp_3 = /(?<=[\d])[\ \t\u00A0\u3000]+(?=[％%])/

        line.gsub(rexp, '')
            .gsub(rexp_2, '')
            .gsub(rexp_3, '')
            .utf8_strip
      end
    end
  end
end
