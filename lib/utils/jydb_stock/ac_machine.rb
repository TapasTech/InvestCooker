# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # ACMachine 初步快速筛选出文章中可能出现的股票名
    class ACMachine
      NAME_CODE_INDEX = Utils::SmoothCache.new('add_stock_codes_ac_index') do |stocks|
        stocks.flat_map do |stock|
          stock.name_list.map { |name| {code: stock.code, name: name} }
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
    end
  end
end
