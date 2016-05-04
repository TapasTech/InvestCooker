Gem::Specification.new do |s|
  s.name        = 'invest_cooker'
  s.version     = '0.2.0'
  s.date        = '2016-04-12'
  s.summary     = "Invest cooker cooks hugo invest system."
  s.description = "Invest cooker cooks hugo invest system."
  s.authors     = ["li-thy-um"]
  s.email       = 'lithium4010@163.com'
  s.files       = [
    "lib/utils.rb",
    "lib/utils/cache.rb",

    "lib/base_document_parser.rb",

    "lib/invest_cooker.rb",

    "lib/invest_cooker/gli.rb",
    "lib/invest_cooker/gli/client.rb",
    "lib/invest_cooker/gli/service.rb",
    "lib/invest_cooker/gli/document_parser.rb",
    "lib/invest_cooker/gli/validator.rb",
    "lib/invest_cooker/gli/record.rb",

    "lib/invest_cooker/cbn.rb",
    "lib/invest_cooker/cbn/client.rb",

    "lib/invest_cooker/mayi.rb",
    "lib/invest_cooker/mayi/client.rb",
    "lib/invest_cooker/mayi/document_parser.rb",
    "lib/invest_cooker/mayi/request_record.rb",

    "lib/invest_cooker/yicai/request_record.rb",
    "lib/invest_cooker/yicai/check_generator.rb",
    "lib/invest_cooker/yicai/push_client.rb",
    "lib/invest_cooker/yicai/client.rb",
    # 经济观察报
    "lib/invest_cooker/jjgcb/client.rb",
    # 一财网编
    "lib/invest_cooker/ycwb/client.rb",

    # invest_admin
    "lib/invest_admin.rb",
    "lib/invest_admin/stock_chinese_name_abbr.rb",
    "lib/invest_admin/statistics_monthly_goal.rb",
    'lib/invest_admin/admin.rb',
    'lib/invest_admin/release_note.rb'
  ]
end
