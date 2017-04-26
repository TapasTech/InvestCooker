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

desc "Depoy to current version to multiple servers"
task :batch_deploy do
  run :local do
    wait = -> (message, health_check_url, &block) {
      check_code = -> { `curl -s -o /dev/null -w "%{http_code}" #{health_check_url}` }
      retry_time = 0

      while !block.(response_code = check_code.call.to_s) && retry_time < 60
        retry_time += 1

        sleep 5
        print_status "wait #{message} ... (#{retry_time})... #{response_code}"
      end

      print_status "wait #{message} ... (#{retry_time})... #{response_code}"
    }

    deploy = -> (stage) {
      print_status "mina #{stage} deploy"
      system "mina #{stage} deploy"
    }

    deploy_stages = ENV['deploy_stages'].to_s.split(';')

    deploy_stages.each do |stage_info|
      stage_name, health_check_url = stage_info.split(',')

      if stage_name.nil? || health_check_url.nil?
        print_error "Invalid stage #{stage}."
        next
      end

      deploy.(stage_name)

      wait.("server to shut down", health_check_url) { |code| code != '204' && code != '200' }
      wait.("server to start up",  health_check_url) { |code| code == '204' || code == '200' }
    end

    print_status 'Done.'
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
