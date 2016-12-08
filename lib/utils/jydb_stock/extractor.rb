require 'concerns/remember'

# Utils::Stock 打股码相关方法
module Utils
  module JYDBStock

    # Extractor 分析文章中股票信息的逻辑
    # 准确提取文章中关联的股票
    class Extractor

      CODES_CHARS = '\^\$\.\w'

      POSSIBLE_STOCK_CODES_REGEXP = Regexp.new(MARKET_ORDER.keys.map { |market_code| "[#{CODES_CHARS}]+\\.#{market_code}" }.join('|'))

      include Remember

      def initialize(content)
        @content = content
      end

      attr_accessor :content

      # 文章中的股票名 => 股票代码列表
      def stock_name_map_codes
        return {} if content.blank?
        ignore_names.each { |ignore, _encounter| stock_info.delete(ignore) }
        stock_info
      end

      # 文章中出现的需要打股码的所有股票的中文
      def name_list
        stock_codes = stock_name_map_codes.values.flatten.uniq

        stocks_name_codes_data
          .select { |code, *names| stock_codes.include?(code) }
          .flat_map { |code, *names| names }
          .uniq
      end

      # 文章中打上的股码
      def possible_stock_codes
        content.scan(POSSIBLE_STOCK_CODES_REGEXP).uniq
      end

      # 1. 根据优先级找到文章中所有可能的股票名
      # 2. 找到文中可能的相关股票
      def stock_info
        # Ahocorasick 找到的不需要再 scan 一次了
        if ENV['Ahocorasick']
          stocks_name_codes_data

        else
          stocks_name_codes_data
            .map { |code, *name_list| {name: name_list.find_obj(&content.method(:index)), code: code} }
            .select { |info| info[:name].present? }

        end.group_by { |info| info[:name] }
           .map { |name, infos| [name, extract_stock_codes_from_info(infos)] }
           .to_h
      end

      # 这里利用 index 快速筛掉大部分股票
      # 做了新旧版平滑处理
      def stocks_name_codes_data
        Index.new(@content).stocks_name_codes_data
      end

      # 相关股票代码表
      def relative_codes
        $relative_codes || InvestAdmin::RelativeStock.code_hash
      end

      # 处理特殊的情况，遇到对应的 encounter 的股票名，要忽略 encounter 中包含的 ignore 部分的股票名
      # 也就是说 encounter 字符串必然包含 ignore 字符串
      # 只有二者出现次数相同时才忽略
      def ignore_names
        stock_names = stock_info.keys

        StockNameTakeover
          .where(:encounter.in => stock_names)
          .where(:ignore.in => stock_names)
          .map { |t| [t.ignore, t.encounter] }
          .select { |i, e| content.scan(i).count == content.scan(e).count }
          .map { |i, _| i }
      end

      remember :stock_name_map_codes, :name_list, :possible_stock_codes,
        :stock_info, :stocks_name_codes_data,
        :relative_codes, :ignore_names

      # 1. info 中的 code
      # 2. 找到 code 关联的 codes
      # 3. codes || code
      def extract_stock_codes_from_info(infos)
        infos.flat_map { |info| relative_codes[info[:code]] || info[:code] }.uniq
      end
    end
  end
end
