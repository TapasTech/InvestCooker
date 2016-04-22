# 用来记录管理员信息以发邮件
module InvestAdmin
  class Admin
    include Mongoid::Document

    field :name,              type: String
    field :email,             type: String
    field :cell_phone_number, type: String
  end
end
