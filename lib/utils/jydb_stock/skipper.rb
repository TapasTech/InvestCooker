# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # Skipper 分析文章中打股码需要跳过次
    class Skipper

      def initialize(content)
        @content = content
      end

      attr_accessor :content

      # 计算给一个股票打股码要跳过前面的多少次匹配
      def skip(name)
        return 0 if content.index(name).blank?

        fake_indexes = fake_indexes_for_skip(name)

        content_index_scan(name)
          .each_with_index
          .take_while { |name_index, index| fake_indexes[index] == name_index }.count
      end

      private

      # 找出文中所有股票名包含该名字的股票名的开始位置
      # e.g.
      #   when content == "中国南方航空股份 南方航空"
      #   assert_true fake_indexes_for_skip('南方航空') == [2]
      def fake_indexes_for_skip(name)
        name_list
          .map { |fake| [fake, fake.index(name)] }
          .select { |fake, index| index && fake != name }
          .flat_map { |fake, index| content_index_scan(fake).map { |i| i + index } }
          .uniq
      end

      # 缓存
      def content_index_scan(name)
        @content_index_scan_cache ||= {}
        indexes = @content_index_scan_cache[name]

        if result.blank?
          indexes = content.index_scan(name)
          @content_index_scan_cache[name] = indexes
        end

        indexes
      end
    end
  end
end
