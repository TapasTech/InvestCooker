ensure! :application_name
ensure! :build_files

set :stages_dir, 'config/mina'
set :default_stage, 'staging'
set :host_ip, "$(ifconfig eth0 | grep inet | awk '{print $2}')"

require 'mina/multistage'
require 'mina/bundler'
require 'mina/git'
require 'mina/deploy'

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup do
  invoke :setup

  in_path fetch(:shared_path) do
    fetch(:shared_files)
      .each { |file| command "touch #{fetch(:shared_path)}/#{file}" }
      .each { |file| comment "Be sure to edit '#{fetch(:shared_path)}/#{file}'." }
  end
end

desc "Deploys the current version to the server."
task :deploy do
  on :before_hook do
    # Put things to run locally before ssh
  end

  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'deploy:cleanup'

    on :launch do
      command "touch #{fetch(:deploy_to)}/last_version"
      invoke :'application:build'
      invoke :'application:restart'
    end
  end
end

namespace :application do
  desc 'Copy files & directories into /target for DockerFile.'
  task :build do
    comment 'build application'

    in_path(fetch(:current_path)) do
      command "mkdir -p ./target"
      fetch(:build_files).each { |file| command "cp -a ./#{file} ./target/" }
    end
  end

  desc 'Restart the application.'
  task :restart do
    comment 'restart with docker'

    in_path(fetch(:current_path)) do
      command "host_ip=#{fetch(:host_ip)} \\
        docker-compose --project-name #{fetch(:application_name)} \\
        up --force-recreate --build -d"
    end
  end

  desc 'Scale the application.'
  task :scale do
    scale = ENV.fetch('scale') { puts "WARN: Please set scale. (e.g. scale='api=2' mina application:scale)" } || next
    comment "Scale service #{fetch(:application_name)}"

    in_path(fetch(:current_path)) do
      command "host_ip=#{fetch(:host_ip)} \\
        docker-compose --project-name #{fetch(:application_name)} \\
        scale #{scale}"
    end
  end
end
