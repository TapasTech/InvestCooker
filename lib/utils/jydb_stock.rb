# 直接通过 JYDB 数据库来打股码
module Utils
  module JYDBStock
    STOCK_NAME_CACHE_KEY =
      lambda do |cache_key=nil|
        if cache_key.blank?
          $redis_object.get(KEY_OF_STOCK_NAME_CACHE_KEY)
        else
          $redis_object.set(KEY_OF_STOCK_NAME_CACHE_KEY, cache_key)
          cache_key
        end
      end

    KEY_OF_STOCK_NAME_CACHE_KEY = 'jydb_stock_names_list_key_v1'

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
