# 安装
```
gem 'invest_cooker', git: 'git@github.com:TapasTech/InvestCooker.git'
```

# 使用
```
在 config/initializers/invest_cooker.rb 中 require 需要的模块
```

# 内容
```
- InvestCooker
  - GLI
    - Client  # 聚源文件服务器的客户端
    - Service # 聚源文件服务器的文件读取程序, 提供了读取当天新文件的功能
    - DocumentParser # 把 Invest::Information 转换为聚源数据交换服务器需要的 hash
    - Validator # 校验聚源输入的文章
    - Record # 用来记录每日读取的聚源文件
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
    - Client # 读取一财网 SOAP 的客户端
  - JJGCB # 经济观察报
    - Client # 读取经济观察报的稿件客户端
  - YCWB # 一财网编
    - Client # 读取一财网编的稿件客户端
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

- InvestCooker::GLI::Validator
```
gem 'nokogiri'

Documnet
Invest::Column
InvestCooker::GLI::Client
Settings.glidata.reject_origin_websites # 聚源来的文章拒收来源列表
```

- InvestCooker::GLI::Record
```
Documnet
::GLI::RecordFileJob
InvestCooker::GLI::Client
InvestCooker::GLI::Service
$redis_object # 连接到 redis 的客户端
Settings.invest_bi.create_gli_record # InvestBI 创建聚源记录接口 url
Settings.invest_web_url # 投研资讯系统地址
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

- InvestCooker::YICAI::PushClient
```
gem 'rest-client'
gem 'oj'

Settings.yicai[type].url #一财文章类型对应的 url
InvestCooker::YICAI::RequestRecord
```

- InvestCooker::YICAI::Client
```
gem 'savon'

Base64
Hash#find_by_key(key) # 搜索一个 hash 中 key 的 value
::YICAI::ExtractZipJob
Settings.yicai.zip_folder # 解压目录名
ENV['HUGO_INVEST_SERVER_YICAI_ACCOUNT']
ENV['HUGO_INVEST_SERVER_YICAI_PASSWORD']
```

- InvestCooker::JJGCB::Client
```
wget
::JJGCB::ExtractRARJob
Settings.jjgcb.ftp # 经济观察报 FTP 地址
ENV['HUGO_INVEST_SERVER_JJGCB_USERNAME'] # 经济观察报 FTP 用户名
ENV['HUGO_INVEST_SERVER_JJGCB_PASSWORD'] # 经济观察报 FTP 密码
Settings.jjgcb.rar_folder # 经济观察报解压地址
```

- InvestCooker::YCWB::Client
```
gem 'rest-client'

::YCWB::ReadListJob
Digest::MD5
ENV['HUGO_INVEST_SERVER_YCWB_KEY'] # 秘钥
```
