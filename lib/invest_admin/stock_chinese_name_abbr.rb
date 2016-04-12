module InvestAdmin
  class StockChineseNameAbbr
    include Mongoid::Document

    field :chinese_name_abbr, type: String
    field :code             , type: String
  end
end
