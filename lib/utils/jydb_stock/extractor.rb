# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # Extractor 分析文章中股票信息的逻辑
    # 准确提取文章中关联的股票
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

      # 找出文中所有股票名包含该名字的股票名的开始位置
      # e.g.
      #   when content == "中国南方航空股份 南方航空"
      #   assert_true fake_indexes_for_skip('南方航空') == [2]
      def fake_indexes_for_skip(name)
        name_list
        .select { |fake| fake.index(name) && fake != name }
        .flat_map { |fake| content.index_scan(fake).map { |i| i + fake.index(name) } }.uniq
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

      # 1. 根据优先级找到文章中所有可能的股票名
      # 2. 找到文中可能的相关股票
      def stock_info
        @stock_info ||= begin
          relative_codes = InvestAdmin::RelativeStock.code_hash

          stocks_name_codes_data
            .map { |code, *name_list| {name: name_list.find_obj(&content.method(:index)), code: code} }
            .select { |info| info[:name].present? }
            .group_by { |info| info[:name] }
            .map { |name, infos| [name, EXTRACT_STOCK_CODES_FROM_INFO[infos, relative_codes]] }
            .to_h
        end
      end

      # 这里利用 index 快速筛掉大部分股票
      # 做了新旧版平滑处理
      def stocks_name_codes_data
        @stocks_name_codes_data ||= begin
          ac = Utils::JYDBStock::ACMachine.new(@content)

          if ac.ready?
            ac.stocks_name_codes_data
          else
            index = Utils::JYDBStock::Index.new(@content)
            if index.ready?
              index.stocks_name_codes_data
            else
              CACHE.fetch
            end
          end
        end
      end

      CACHE = Utils::SmoothCache.new('add_stock_codes_cache') do |stocks|
        stocks.map { |stock| [stock.code] + stock.name_list }.to_a
      end

      CODES_CHARS = '\^\$\.\w'

      POSSIBLE_STOCK_CODES_REGEXP =
        # Regexp.new("[#{CODES_CHARS}]+\\.(?:#{MARKET_ORDER.keys.join('|')})") # 修岑的方法，简单测试过可用
        Regexp.new(MARKET_ORDER.keys.map { |market_code| "[#{CODES_CHARS}]+\\.#{market_code}" }.join('|'))

      EXTRACT_STOCK_CODES_FROM_INFO = lambda do |infos, relative_codes|
        # 1. info 中的 code
        # 2. 找到 code 关联的 codes
        # 3. codes || code
        infos.map { |info| info[:code] }
        .flat_map { |code| relative_codes[code] || code }
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
