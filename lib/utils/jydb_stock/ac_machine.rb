# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # ACMachine 初步快速筛选出文章中可能出现的股票名
    class ACMachine
      NAME_CODE_INDEX = Utils::SmoothCache.new('add_stock_codes_ac_index') do |stocks|
        stocks.flat_map do |stock|
          stock.name_list.each_with_index.map { |name, i| {code: stock.code, name: name, o: i} }
        end.group_by { |hash| hash[:name] }
      end

      attr_accessor :content, :name_index

      def initialize(content)
        self.content = content
        self.name_index  = $ac_name_index
      end

      # @return [[code, name1, name2, ...], ...]
      def stocks_name_codes_data
        stock_names = $ahocorasick.lookup(content)

        stock_names
          .map { |name| name_index[name] }
          .flatten(1)
          .group_by { |hash| hash[:code] }
          .map      { |code, list| __ordered_names__(list).unshift(code) }
      end

      def __ordered_names__(list)
        return [list.first[:name]] if list.size == 1

        if list.first[:o].present?
          # 新数据带有排序信息
          list.sort_by { |hash| hash[:o] }.map { |hash| hash[:name] }.uniq
        else
          # 兼容旧数据
          list.map { |hash| hash[:name] }.uniq.sort_by { |name| -name.size }
        end
      end
    end
  end
end
