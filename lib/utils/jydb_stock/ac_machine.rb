# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # ACMachine 初步快速筛选出文章中可能出现的股票名
    # 和 Index 共用 ready? 和 stock_name_map_codes 这两个接口
    class ACMachine < Index

      NAME_CODE_INDEX = Utils::SmoothCache.new('add_stock_codes_ac_index') do |stocks|
        stocks.flat_map do |stock|
          stock.name_list.map { |name| {code: stock.code, name: name} }
        end.group_by { |hash| hash[:name] }
      end

      def initialize(content)
        @content = content
      end

      def ready?
        @stock_names ||= ac_search(@content)

        @stock_names.present?
      end

      # @return [[code, name1, name2, ...], ...]
      def stocks_name_codes_data
        name_index = NAME_CODE_INDEX.fetch

        @stock_names ||= ac_search(@content)

        @stock_names
          .map { |name| name_index[name] }
          .flatten(1)
          .group_by { |hash| hash[:code] }
          .map      { |code, list| __ordered_names__(list).unshift(code) }
      end

      private

      def ac_search(content)
        payload = Oj.dump({content: content}.as_json)
        response = RestClient.post(ENV['SMAUG_SEARCH_AC_URL'], payload, content_type: :json)
        Oj.load(response.body)
      rescue
        []
      end
    end
  end
end