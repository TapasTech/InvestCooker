require 'concerns/remember'
require 'utils/jydb_stock/adder'
require 'utils/jydb_stock/extractor'
require 'utils/jydb_stock/skipper'
require 'utils/jydb_stock/ac_machine'

# 直接通过 JYDB 数据库来打股码
module Utils
  module JYDBStock

    # 打股码
    def add_stock
      format_content!
      add_stock_codes!

      yield possible_stock_codes if block_given?
    end

    # 可能已经加过标签，先把标签去掉
    # 要求对象 include Utils::ContentFormat
    def format_content!
      clear_style_of_content_2
      remove_stock_code_suffix
    end

    def possible_stock_codes
      Extractor.new(@content).possible_stock_codes
    end

    def add_stock_codes!
      mapping = extractor.stock_name_map_codes

      mapping.each_pair do |name, codes|
        skip = skipper.skip(name)
        Adder.new(@content, name, codes, skip).add_one_stock_code
      end
    end

    def extractor
      content_text = Nokogiri::HTML.fragment(@content).content

      Extractor.new(content_text)
    end

    def skipper
      Skipper.new(extractor.content, extractor.name_list)
    end

    include Remember
    remember :extractor, :skipper
  end
end
