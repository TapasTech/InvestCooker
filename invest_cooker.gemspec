Gem::Specification.new do |s|
  s.name      = 'invest_cooker'
  s.version  = '1.27.4'
  s.date     = '2016-04-12'
  s.summary  = 'Invest cooker cooks hugo invest system.'
  s.homepage = 'https://github.com/TapasTech/InvestCooker'
  s.authors  = ['lifeng']
  s.email    = 'lifeng@dtcj.com'
  s.licenses = ['Nonstandard']
  s.files    = Dir[File.join("**", "lib", "**", "*.rb")]

  s.add_dependency 'activesupport'
  s.add_dependency 'aliyun-sdk'
  s.add_dependency 'fastimage'
end
