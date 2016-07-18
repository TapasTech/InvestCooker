Gem::Specification.new do |s|
  s.name        = 'invest_cooker'
  s.version     = '0.2.13'
  s.date        = '2016-04-12'
  s.summary     = 'Invest cooker cooks hugo invest system.'
  s.description = 'Invest cooker cooks hugo invest system.'
  s.authors     = ['li-thy-um']
  s.email       = 'lithium4010@163.com'
  s.files       = [
    'lib/utils.rb',
    'lib/utils/cache.rb',
    'lib/utils/content_format.rb',
    'lib/utils/image.rb',
    'lib/utils/jydb_stock.rb',
    'lib/utils/random.rb',
    'lib/utils/rsa.rb',
    'lib/utils/smooth_cache.rb',
    'lib/utils/jydb_stock/adder.rb',
    'lib/utils/jydb_stock/extractor.rb',
    'lib/utils/content_format/basic_formatter.rb',
    'lib/utils/content_format/html_formatter.rb',
    'lib/utils/content_format/string_formatter.rb',

    'lib/invest_cooker.rb',
    'lib/invest_cooker/base_document_parser.rb',
    'lib/invest_cooker/gli.rb',
    'lib/invest_cooker/gli/client.rb',
    'lib/invest_cooker/gli/service.rb',
    'lib/invest_cooker/gli/document_parser.rb',
    'lib/invest_cooker/gli/validator.rb',
    'lib/invest_cooker/gli/record.rb',
    'lib/invest_cooker/cbn.rb',
    'lib/invest_cooker/cbn/client.rb',
    'lib/invest_cooker/mayi.rb',
    'lib/invest_cooker/mayi/client.rb',
    'lib/invest_cooker/mayi/document_parser.rb',
    'lib/invest_cooker/mayi/request_record.rb',
    'lib/invest_cooker/yicai/request_record.rb',
    'lib/invest_cooker/yicai/check_generator.rb',
    'lib/invest_cooker/yicai/push_client.rb',
    'lib/invest_cooker/yicai/client.rb',
    'lib/invest_cooker/jjgcb/client.rb',
    'lib/invest_cooker/ycwb/client.rb',

    # invest_admin
    'lib/invest_admin.rb',
    'lib/invest_admin/relative_stock.rb',
    'lib/invest_admin/stock_chinese_name_abbr.rb',
    'lib/invest_admin/statistics_monthly_goal.rb',
    'lib/invest_admin/admin.rb',
    'lib/invest_admin/release_note.rb',
    'lib/invest_admin/origin_website_merge_rule.rb',
    'lib/invest_admin/mayi_live_origin_website_output_black_list.rb',
    'lib/invest_admin/compose_organization_merge_rule.rb'
  ]
end
