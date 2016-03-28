# 安装
```
gem 'invest_cooker', git: 'git@github.com:TapasTech/InvestCooker.git'
```

# 内容
```
- InvestCooker
  - GLI
    - Client  # 聚源文件服务器的客户端
    - Service # 聚源文件服务器的文件读取程序, 提供了读取当天新文件的功能
    - DocumentParser # 把 Invest::Information 转换为聚源数据交换服务器需要的 hash
  - CBN
    - Client # 读取投研团队生产的新闻文件客户端
  - MAYI
    - Client # 蚂蚁新链路客户端
    - DocumentParser # Invest::Information 转换为蚂蚁接口需要的 hash
    - RequestRecord # 请求记录
  - YICAI
    - RequestRecord # 请求记录
    - CheckGenerator # 签名生成器
    - PushClient # 推送文章给一财的客户端
```

# 依赖

- InvestCooker::GLI::Client

```
gem 'monadic' # 因为用到了 Try

Settings.glidata.source_path # 读取文件的地址
Settings.glidata.target_path # 写入文件的地址

$gli_sftp_pool # 需要兼容 gem 'connection_pool', 可以得到 gli 服务器的 sftp 链接
```

- InvestCooker::GLI::Service

```
gem 'oj'

InvestCooker::GLI::Client 或兼容其接口的 client 对象
::GLI::ReadDataJob # ActiveJob 用来读取聚源文件

$redis_gli # 连接到 redis 的客户端
```

- InvestCooker::GLI::DocumentParser
```
Documnet
Invest::Information
Invest::OutputColumn
```

- InvestCooker::CBN::Client

```
gem 'oj'
gem 'kaminari'

Settings.glidata.target_path # 读取文件的地址, 也就是 InvestCooker::GLI::Client 的写入文件的地址

$gli_sftp_pool # 需要兼容 gem 'connection_pool', 可以得到 gli 服务器的 sftp 链接
```

- InvestCooker::MAYI::Client
```
gem 'rest-client'
gem 'oj'

InvestCooker::MAYI::RequestRecord # 请求记录
Settings.mayi.urls[api_name][action_name] # 蚂蚁 API:Action 对应的 url 地址配置
Utils::RSA # RSA签名工具
```

- InvestCooker::MAYI::DocumentParser
```
gem 'oj'

Document
Invest::Information
Invest::OutputColumn
ActiveSupport::Gzip
Base64
Utils::Image # 图片工具类
Settings.mayi.date_format # 日期格式
Settings.max_image_size # 最大图片大小
```

- InvestCooker::MAYI::RequestRecord
```
gem 'mongoid'
gem 'kaminari'
```

- InvestCooker::YICAI::RequestRecord
```
gem 'mongoid'
gem 'kaminari'
```

- InvestCooker::YICAI::CheckGenerator
```
Digest::MD5
ENV['HUGO_INVEST_SERVER_YICAI_APP_KEY']
```

－ InvestCooker::YICAI::PushClient
```
gem 'rest-client'
gem 'oj'

Settings.yicai[type].url #一财文章类型对应的 url
InvestCooker::YICAI::RequestRecord
```
