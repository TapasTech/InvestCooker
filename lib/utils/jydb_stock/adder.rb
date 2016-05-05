# Utils::JYDBStock 直接通过 JYDB 来打股码
# Adder 不需要针对 JYDB 修改
module Utils
  module JYDBStock

    MARKET_ORDER = {
      'SH' => 0,
      'SZ' => 1,
      'HK' => 2,
      'US' => 3,
      'OF' => 4
    }

    # Adder 给文章打股码的逻辑
    class Adder

      attr_accessor :content, :name, :codes, :skip

      def initialize(content, name, codes, skip)
        @content, @name, @codes, @skip = content, name, codes, skip
      end

      def add_one_stock_code
        name_index.blank? && return
        # 检查是否已经打好股码
        content.index(tag) && return
        # 只替换首次匹配上的
        content[name_index..-1] = replace_text.sub!(stock_name_in_content, tag)
      end

      def replace_text
        @replace_text ||= content[name_index..-1]
      end

      # 如果匹配处已打好标准或部分标准股码
      def stock_name_in_content
        @stock_name_in_content ||=
          STANDARD_STOCK_STRINGS[name, codes].find do |standard_stock_str|
            replace_text.index(standard_stock_str) == 0
          end || name
      end

      # 替换的开始位置
      def name_index
        @name_index ||= content.index_scan(name)[skip]
      end

      # 完整的股票标签
      def tag
        @tag ||= HIGHLIGHT_STOCK_CODE[name, codes]
      end

      def codes_with_sort
        # 股码按照 A/B/H/U 排序
        codes_without_sort.sort_by { |code| MARKET_ORDER[code[-2..-1]] }
      end

      alias_method_chain :codes, :sort

      STANDARD_STOCK_STRINGS = lambda do |name, codes|
        codes.size.times
        .flat_map { |index| codes.permutation(index + 1).to_a }
        .map(&FORMAT_STOCK_STRING.curry[name])
      end

      FORMAT_STOCK_STRING = ->(name, codes) { "#{name}（#{codes.join('；')}）" }

      # 股码高亮
      HIGHLIGHT_STOCK_CODE = lambda do |name, codes|
        "<span class=\"hugo-stock-code\">#{FORMAT_STOCK_STRING[name, codes]}</span>"
      end
    end
  end
end
