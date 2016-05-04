# Utils::Stock 打股码相关方法
module Utils
  module Stock
    STOCK_NAME_CACHE_KEY = 'stock_names_list_v11'

    # 首次出现股票名称时，如果名称前后20字符内没有股票代码，加上股票代码。
    def add_stock_codes
      extractor = Extractor.new(content.clone)
      # 可能已经加过标签，先把标签去掉
      # 要求对象 include Utils::ContentFormat
      remove_stock_code_highlight
      extractor.stock_name_map_codes.each_pair do |name, codes|
        Adder.new(content, name, codes, extractor.skip(name)).add_one_stock_code
      end
      content
    end

    def extract_possible_stock_codes
      Extractor.new(content.clone).possible_stock_codes
    end

    def extract_stock_name_map_codes
      Extractor.new(content.clone).stock_name_map_codes
    end
  end
end
