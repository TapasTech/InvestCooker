# 标准部署启动脚本，最好配合 invest_deploy 使用。
# 封装了定义启动 server 和 job 脚本的 rake 任务，job 进程为 sidekiq
# 封装了 God 启动脚本

# need to define methods:
#   current_path: the root_path of the application
#   app_name: the identity of the application

# Example
# 0. 准备好环境变量 ENV['HUGO_PARK_PROCESS_PORTS']

# 1. config/job/*.yml 这里写 job 的 yml

# 2. config/god.rb 一定要用 bundle exec 启动 god，不然无法 require 'startup_helpers'
#
#   require 'startup_helpers'
#
#   def current_path
#     File.expand_path('../..', __FILE__)
#   end
#
#   def app_name
#     'HUGO_PARK'
#   end
#
#   start_god config_job: ->(w) { w.keepalive memory_max: 512.megabytes },
#             config_server: ->(w) { w.keepalive memory_max: 256.megabytes }

# 3. lib/tasks/startup.rake
#   require 'startup_helpers'
#
#   def current_path
#     File.expand_path('../../..', __FILE__)
#   end
#
#   def app_name
#     'HUGO_PARK'
#   end
#
#   namespace :server do
#     initial_server_tasks
#   end
#
#   namespace :job do
#     initial_job_tasks
#   end

def pid_path
  File.expand_path('tmp/pids/', current_path)
end

def job_processes
  path = File.expand_path("config/job/", current_path)
  Dir.foreach(path)
    .select { |file_name| file_name =~ /\.yml$/ }
    .map { |file_name| file_name[0...-4] }
end

def server_processes
  ENV["#{app_name}_PROCESS_PORTS"].to_s.split(',').to_a
end

def initial_server_tasks
  server_processes.each do |port|
    namespace :"#{port}" do
      desc 'Start server'
      task :start do
        app_config = File.expand_path('config.ru', current_path)
        pid_file = File.expand_path("server.#{port}.pid", pid_path)
        system "cd #{current_path} && bundle exec thin -e #{ENV['RAILS_ENV']} -R #{app_config} -p #{port} --pid #{pid_file} start --threaded -d"
      end

      desc 'Stop server'
      task :stop do
        pid_file = File.expand_path("server.#{port}.pid", pid_path)
        system "cd #{current_path} && bundle exec thin stop --pid #{pid_file}"
      end

      desc 'Restart server'
      task restart: [:stop, :start]
    end
  end
end

# TODO 如果修改环境配置减少 processes 的话，不会自动停掉减少的那些 processes. 如果能够检测到正在运行的 processes 名字，就可以优化这个问题
def initial_job_tasks
  command_template = <<-CMD.strip_heredoc
    if cd "#{current_path}" && %s; then
      echo 'Done'
    else
      echo 'Failed'
    fi
  CMD

  quiet_template = '[ -f "%{pid_path}" ] && kill -USR1 `cat "%{pid_path}"`> /dev/null 2>&1'
  stop_template  = '[ -f "#{pid_path}" ] && kill -TERM `cat "%{pid_path}"`> /dev/null 2>&1 -d'
  start_template = "bundle exec sidekiq -e #{ENV['RAILS_ENV']} -C %{yml_path} -L %{log_path} -P %{pid_path} -d"

  define_task = lambda do |task, command, process|
    desc "[job] #{task.capitalize}\t#{process}"
    task task.to_sym do
      print "[job] Running\t:#{task}\t<#{process}>..."
      system(command_template % command)
    end
  end

  job_processes.each do |process|
    namespace process do

      paths = {
        yml_path: File.expand_path("config/job/#{process}.yml", current_path),
        log_path: File.expand_path("log/job.#{process}.log", current_path),
        pid_path: File.expand_path("job.#{process}.pid", pid_path)
      }

      tasks = {
        quiet: (quiet_template % paths),
        stop:  (stop_template  % paths),
        start: (start_template % paths)
      }

      tasks.each do |task, command|
        define_task.call task, command, process
      end

      desc "[job] Restart #{process} "
      task restart: [:stop, :start]
    end
  end

  desc "重启所有 job"
  task restart: job_processes.map { |t| :"#{t}:restart" }

  desc "所有 job 停止接收新任务"
  task quiet: job_processes.map { |t| :"#{t}:quiet" }
end

def start_god(config_job: nil, config_server: nil)
  god_commands = [:start, :stop, :restart]

  server_processes.each do |port|
    God.watch do |w|
      w.group    = app_name
      w.name     = "server:#{port}"
      w.pid_file = File.expand_path("server.#{port}.pid", pid_path)

      god_commands.each { |command| w.send("#{command}=", "cd #{current_path} && bundle exec rake server:#{port}:#{command}") }

      config_server.call(w) if config_server.respond_to?(:call)
    end
  end

  job_processes.each do |process|
    God.watch do |w|
      w.group    = "#{app_name}_jobs"
      w.name     = "job:#{process}"
      w.pid_file = File.expand_path("job.#{process}.pid", pid_path)

      god_commands.each { |command| w.send("#{command}=", "cd #{current_path} && bundle exec rake job:#{process}:#{command}") }

      config_job.call(w) if config_job.respond_to?(:call)
    end
  end
end
