# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # Index 初步快速筛选出文章中可能出现的股票名
    class Index

      # {first_word => [{name:, code:}, ...]}
      NAME_INDEX = Utils::SmoothCache.new('add_stock_codes_index_name') do |stocks|
        stocks.flat_map do |stock|
          stock.name_list.map { |name| {code: stock.code, name: name} }
        end.group_by { |hash| hash[:name].first }
      end

      def initialize(content)
        @content = content
        @name_index = NAME_INDEX.fetch
      end

      def ready?
        @name_index.present?
      end

      # [[code, name1, name2, ...], ...]
      def stocks_name_codes_data
        keys = @content.chars.uniq & @name_index.keys

        @name_index.values_at(*keys).flatten(1).uniq
          .group_by { |hash| hash[:code] }
          .map      { |code, list| __ordered_names__(list).unshift(code) }
      end

      private

      # NOTE 这里文中股票名称的排序不再依照 name_list 的顺序了
      def __ordered_names__(list)
        return [list.first[:name]] if list.size == 1
        list.map { |hash| hash[:name] }.uniq.sort_by { |name| -name.size }
      end
    end
  end
end
