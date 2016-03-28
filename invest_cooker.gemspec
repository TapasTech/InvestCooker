Gem::Specification.new do |s|
  s.name        = 'invest_cooker'
  s.version     = '0.0.5'
  s.date        = '2016-03-12'
  s.summary     = "Invest cooker cooks hugo invest system."
  s.description = "Invest cooker cooks hugo invest system."
  s.authors     = ["li-thy-um"]
  s.email       = 'lithium4010@163.com'
  s.files       = [
    "lib/invest_cooker.rb",

    "lib/invest_cooker/gli.rb",
    "lib/invest_cooker/gli/client.rb",
    "lib/invest_cooker/gli/service.rb",
    "lib/invest_cooker/gli/document_parser.rb",

    "lib/invest_cooker/cbn.rb",
    "lib/invest_cooker/cbn/client.rb",

    "lib/invest_cooker/mayi.rb",
    "lib/invest_cooker/mayi/client.rb",
    "lib/invest_cooker/mayi/document_parser.rb",
    "lib/invest_cooker/mayi/request_record.rb",

    "lib/invest_cooker/yicai/request_record.rb",
    "lib/invest_cooker/yicai/check_generator.rb",
    "lib/invest_cooker/yicai/push_client.rb"
  ]
  s.add_dependency 'kaminari'
  s.add_dependency 'mongoid'
end
