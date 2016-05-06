# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # Extractor 分析文章中股票信息的逻辑
    class Extractor

      def initialize(content)
        @content = content
      end

      attr_accessor :content

      # 计算给一个股票打股码要跳过前面的多少次匹配
      def skip(name)
        return 0 if content.index(name).blank?
        lambda do |fake_indexes|
          content.index_scan(name).each_with_index
          .take_while { |name_index, index| fake_indexes[index] == name_index }.count
        end[fake_indexes_for_skip(name)]
      end

      # 找出文中所有股票名包含该名字的股票名的位置
      def fake_indexes_for_skip(name)
        name_list
        .select { |fake| fake.index(name) && fake != name }
        .flat_map(&content.method(:index_scan)).uniq
      end

      # 文章中出现的需要打股码的所有股票的中文
      def name_list
        @name_list ||=
          begin
            stock_codes = stock_name_map_codes.values.flatten.uniq
            stocks_name_codes_data
              .select { |code, *names| stock_codes.include?(code) }
              .flat_map { |code, *names| names }
              .uniq
          end
      end

      # 文章中的股票名 => 股票代码列表
      def stock_name_map_codes
        return {} if content.blank?
        @stock_name_map_codes ||= begin
          REMOVE_IGNORE[stock_info, content]
          stock_info
        end
      end

      def possible_stock_codes
        @possible_stock_codes ||= content.scan(POSSIBLE_STOCK_CODES_REGEXP).uniq
      end

      def stock_info
        @stock_info ||= begin
          # 1. 根据优先级找到文章中所有可能的股票名
          # 2. 找到文中可能的相关股票
          stocks_name_codes_data
          .map { |code, *name_list| {name: name_list.find_obj(&content.method(:index)), code: code} }
          .select { |info| info[:name].present? }
          .group_by { |info| info[:name] }.each_pair
          .mash { |name, infos| [name, EXTRACT_STOCK_CODES_FROM_INFO[infos]] }
        end
      end

      def stocks_name_codes_data
        @stocks_name_codes_data ||= CACHE_ARRAY.call
      end

      POSSIBLE_STOCK_CODES_REGEXP =
        Regexp.new(MARKET_ORDER.keys.map { |market_code| "[\\^\\w\\d]+\\.#{market_code}" }.join('|'))

      CACHE_ARRAY = lambda do
        # NOTE 手动过期
        Utils::Cache.redis.fetch(STOCK_NAME_CACHE_KEY) do
          # 这里严格按照股票的 name_list 顺序确定优先级
          ::JYDBStock.all.map { |stock| [stock.code] + stock.name_list }.to_a
        end
      end

      EXTRACT_STOCK_CODES_FROM_INFO = lambda do |infos|
        # 1. info 中的 code
        # 2. 找到 code 关联的 codes
        # 3. codes || code
        infos.map { |info| info[:code] }
        .flat_map { |code| InvestAdmin::RelativeStock.where(codes: code).first.try(:codes) || code  }
        .uniq
      end

      REMOVE_IGNORE = lambda do |stock_info, content|
        # 处理特殊的情况，遇到对应的 encounter 的股票名，要忽略 encounter 中包含的 ignore 部分的股票名
        # 也就是说 encounter 字符串必然包含 ignore 字符串
        # 只有二者出现次数相同时才忽略
        lambda do |stock_names|
          StockNameTakeover.where(:encounter.in => stock_names, :ignore.in => stock_names)
          .map { |takeover| [takeover.ignore, takeover.encounter] }
          .select { |ignore, encounter| content.scan(encounter).count == content.scan(ignore).count }
          .each { |ignore, _encounter| stock_info.delete(ignore) }
        end[stock_info.keys]
      end
    end
  end
end
