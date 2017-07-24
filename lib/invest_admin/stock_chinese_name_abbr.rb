# 股票中文名简称
# 股票英文名
module InvestAdmin
  class StockChineseNameAbbr
    include Mongoid::Document

    field :chinese_name_abbr, type: String
    field :english_name,      type: String
    field :code,              type: String

    index code: 1
  end
end
