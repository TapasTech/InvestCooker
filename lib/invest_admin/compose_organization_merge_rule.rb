# InvestAdmin::ComposeOrganizationMergeRule
# 撰写机构合并规则
# 某些情况下，希望源文章的撰写机构在首次编辑时变成另一个撰写机构
class InvestAdmin
  class ComposeOrganizationMergeRule
    include Mongoid::Document

    field :from, type: String
    field :to,   type: String

    validates :to, uniqueness: {scope: :from, message: '只能映射到一个撰写机构'}
  end
end
