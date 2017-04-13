require 'mina/multistage'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'
require 'yaml'

set :host_ip_script, "$(ifconfig eth0 | grep inet | awk '{print $2}')"

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task setup: :environment do
  invoke :setup

  %w(config/settings tmp tmp/pids).each do |dir|
    queue! %(mkdir -p "#{deploy_to}/#{shared_path}/#{dir}")
    queue! %(chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/#{dir}")
  end

  queue! %(mkdir -p /data/log/#{application_name})
  queue! %(ln -s "/data/log/#{application_name}" "#{deploy_to}/#{shared_path}/log")

  shared_files.each do |file|
    queue! %(touch "#{deploy_to}/#{shared_path}/#{file}")
    queue %(echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/#{file}'.")
  end
end

desc 'Copy files & directories into /target for DockerFile.'
task build_application: :environment do
  current_path = "#{deploy_to}/current"
  queue "mkdir -p #{current_path}/target"

  YAML.load_file(File.expand_path('../../build_files.yml', __FILE__)).each do |file|
    queue "cp -a #{current_path}/#{file} #{current_path}/target/"
  end
end

desc 'Restart the application.'
task restart_application: :environment do
  queue 'echo "restart with docker"'
  queue "cd #{deploy_to}/#{current_path}"
  queue "host_ip=#{host_ip_script} docker-compose -p #{application_name} up --force-recreate --build -d"

  if staging.to_s == 'prod_service'
    # 因为 invest_service 上的 invest_node 依赖 4599 端口的 Smaug
    queue "sudo ruby -v \\
      && sudo ruby register.rb #{application_name}_api \\
      || ruby register.rb #{application_name}_api"
  end
end

desc 'Scale the application.'
task scale_application: :environment do
  queue "echo 'Scale service #{application_name}'"
  queue "cd #{deploy_to}/#{current_path}"
  queue "host_ip=#{host_ip_script} docker-compose -p #{application_name} scale api=#{ENV.fetch('api') { 1 }}"
end

desc "Deploys the current version to the server."
task deploy: :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'deploy:cleanup'

    to :launch do
      queue "touch #{deploy_to}/last_version"

      invoke :build_application
      invoke :restart_application
    end
  end
end
