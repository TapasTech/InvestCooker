# InvestAdmin::OriginWebsiteMergeRule
# 新闻来源合并规则
# 某些情况下，希望源文章的新闻来源在首次编辑时变成另一个新闻来源
module InvestAdmin
  class OriginWebsiteMergeRule
    include Mongoid::Document

    field :from, type: String
    field :to,   type: String

    validates :to, uniqueness: {scope: :from, message: '只能映射到一个新闻来源'}

    belongs_to :team, index: true
  end
end
