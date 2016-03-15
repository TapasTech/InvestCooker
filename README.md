# 安装
```
gem 'invest_cooker', git: 'git@github.com:TapasTech/InvestCooker.git'
```

# 内容
```
- InvestCooker
  - GLI
    - Client # 聚源文件服务器的客户端
```

# 依赖

- InvestCooker::GLI::Client

```

gem 'monadic' # 因为用到了 Try

Settings.glidata.source_path # 读取文件的地址
Settings.glidata.target_path # 写入文件的地址

$gli_sftp_pool # 需要兼容 gem 'connection_pool'; 可以得到 gli 服务器的 sftp 链接
```
