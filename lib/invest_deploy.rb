desc 'Restart the application.'
task restart_application: :environment do
  invoke :info_deployment
  queue "
    # god 正在运行, terminate 后重启
    god -p #{god_port} status  &&
    echo 'God is active, now god.terminate.' &&
    god -p #{god_port} terminate &&
    echo 'God is terminated, now god.init with config file.' &&
    god -p #{god_port} -c #{deploy_to}/#{current_path}/config/god.rb -l /data/log/god.log ||

    # god 没有运行, 启动
    echo 'God is terminated, now god.init with config file.' &&
    god -p #{god_port} -c #{deploy_to}/#{current_path}/config/god.rb -l /data/log/god.log
  "
end

desc 'Info deployment.'
task info_deployment: :environment do
  # queue "
  #   echo '这次部署需要:'
  #   echo 'mina production rake[information:migrate_special_subject_add_category_active]'
  #   echo '部署完毕请删除 /config/deploy.rb 中的相关提醒'
  # "
end

desc 'Restart the application fast.'
task fast_restart: :environment do
  invoke :info_deployment
  queue "
    # god 正在运行, 重启
    god -p #{god_port} status &&
    echo 'God is active, now god.restart.' &&
    god -p #{god_port} restart ||

    # god 没有运行, 启动
    echo 'God is terminated, now god.init with config file.' &&
    god -p #{god_port} -c #{deploy_to}/#{current_path}/config/god.rb -l /data/log/god.log
  "
end

desc 'Terminate the application.'
task terminate_application: :environment do
  invoke :info_deployment
  queue "
    # god 正在运行, terminate
    god -p #{god_port} status &&
    echo 'God is active, now god.terminate.' &&
    god -p #{god_port} terminate ||

    # god 没有运行
    echo 'God is terminated.'
  "
end

# For system-wide RVM install.
set :rvm_path, '/usr/local/rvm/bin/rvm'

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-2.2.2]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task setup: :environment do
  invoke :setup
  %w(config/settings tmp).each do |dir|
    queue! %(mkdir -p "#{deploy_to}/#{shared_path}/#{dir}")
    queue! %(chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/#{dir}")
  end
  queue! %(mkdir -p /data/log/hugo_invest_server)
  queue! %(ln -s "/data/log/hugo_invest_server" "#{deploy_to}/#{shared_path}/log")
  shared_files.each do |file|
    queue! %(touch "#{deploy_to}/#{shared_path}/#{file}")
    queue %(echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/#{file}'.")
  end
end