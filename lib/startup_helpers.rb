# 标准部署启动脚本，最好配合 invest_deploy 使用。
# 封装了定义启动 server 和 job 脚本的 rake 任务，job 进程为 sidekiq
# 封装了 God 启动脚本

# need to define methods:
#   current_path: the root_path of the application
#   app_name: the identity of the application
#   sneaker_processes: the sneaker process names (size should equal 1)
#   sneaker_workers: the sneaker worker classes

# initial_job_tasks
# - require_file: nil, 填写文件路径会在启动 job 进程的时候 require 相关文件
# - quiet_stop: false, 设为 true 会采用先 quiet job 进程，再启动新 job 进程，最后 kill -TERM 所有 quiet 的 job 进程的方式来重启

# Example:

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
  if Dir.exists?(path)
    Dir.foreach(path)
       .select { |file_name| file_name =~ /\.yml$/ }
       .map { |file_name| file_name[0...-4] }
  else
    []
  end
end

def server_processes
  ENV["#{app_name}_PROCESS_PORTS"].to_s.split(',').to_a
end

# needs to override
def sneaker_processes
  []
end

# needs to override
def sneaker_workers
  []
end

def start_god(config_job: nil, config_server: nil, config_sneaker: nil)
  {
    job: config_job,
    server: config_server,
    sneaker: config_sneaker
  }.each { |type, callback| start_god_meta(type, callback) }
end

def initial_server_tasks
  stop_template  = "cd #{current_path} && bundle exec thin stop --pid %{pid_path}"
  start_template = "cd #{current_path} && bundle exec thin -e #{ENV['RAILS_ENV']} -R %{config_path} -p %{port} --pid %{pid_path} start --threaded -d"

  initial_tasks_meta :server do |process|
    paths = {
      config_path: File.expand_path('config.ru', current_path),
      pid_path: File.expand_path("server.#{process}.pid", pid_path),
      port: process
    }

    {
      stop: (stop_template % paths),
      start: ( start_template % paths)
    }
  end
end

# TODO 如果修改环境配置减少 processes 的话，不会自动停掉减少的那些 processes. 如果能够检测到正在运行的 processes 名字，就可以优化这个问题
def initial_job_tasks(require_file: nil, quiet_stop: false)
  quiet_template = '[ -f "%{pid_path}" ] && kill -USR1 `cat "%{pid_path}"`> /dev/null 2>&1'
  stop_template  = '[ -f "%{pid_path}" ] && kill -TERM `cat "%{pid_path}"`> /dev/null 2>&1 -d'
  start_template = "cd #{current_path} && bundle exec sidekiq -e #{ENV['RAILS_ENV']} -C %{yml_path} -L %{log_path} -P %{pid_path} -d"

  if !require_file.nil?
    start_template = "cd #{current_path} && bundle exec sidekiq -r #{require_file} -e #{ENV['RAILS_ENV']} -C %{yml_path} -L %{log_path} -P %{pid_path} -d"
  end

  if quiet_stop
    stop_template = "#{quiet_template} && rm -f %{pid_path}"
    start_template = "#{start_template} && ps -ef | grep sidekiq | grep stopping | awk '{print $2}' | xargs kill -TERM"
  end

  initial_tasks_meta :job, quiet: true do |process|
    paths = {
      yml_path: File.expand_path("config/job/#{process}.yml", current_path),
      log_path: File.expand_path("log/job.#{process}.log", current_path),
      pid_path: File.expand_path("job.#{process}.pid", pid_path)
    }

    {
      quiet: (quiet_template % paths),
      stop:  (stop_template  % paths),
      start: (start_template % paths)
    }
  end
end

# TODO 这里暂时只支持一个 Worker, 需要改进
#   needs to define method sneaker_tasks
#   needs to define method sneaker_processes
#   needs to define method sneaker_processes
def initial_sneaker_tasks
  stop_template  = '[ -f "%{pid_path}" ] && kill -TERM `cat "%{pid_path}"`> /dev/null 2>&1 -d'
  start_template = "cd #{current_path} && WORKERS=%{workers} bundle exec rake sneakers:run"

  initial_tasks_meta :sneaker do |process|
    paths = {
      pid_path: File.expand_path("sneaker.#{process}.pid", pid_path),
      workers: sneaker_workers.join(',')
    }

    {
      stop: (stop_template % paths),
      start: (start_template % paths)
    }
  end
end

def start_god_meta(type, callback)
  processes = send(:"#{type}_processes")

  return if processes.empty?

  processes.each do |process|
    God.watch do |w|
      w.group    = "#{app_name}_#{type}"
      w.name     = "#{type}:#{process}"
      w.pid_file = File.expand_path("#{type}.#{process}.pid", pid_path)

      [:start, :stop, :restart].each { |command| w.send("#{command}=", "cd #{current_path} && bundle exec rake #{type}:#{process}:#{command}") }

      callback.call(w) if callback.respond_to?(:call)
    end
  end
end

def initial_tasks_meta(type, quiet: false)
  processes = send(:"#{type}_processes")

  return if processes.empty?

  processes.each do |process|
    namespace process do
      tasks = yield process

      tasks.each do |task, command|
        define_task type, task, command, process
      end

      desc "[#{type}] Restart #{process}"
      task restart: [:stop, :start]
    end
  end

  desc "Restart all #{type}"
  task restart_all: processes.map { |t| :"#{t}:restart" }

  if quiet
    desc "所有 #{type} 停止接收新任务"
    task quiet_all: processes.map { |t| :"#{t}:quiet" }
  end
end

def define_task(type, task, command, process)
  command_template = <<-CMD.strip_heredoc
    if cd "#{current_path}" && %s; then
      echo 'Done'
    else
      echo 'Failed'
    fi
  CMD

  desc "[#{type}] #{task.capitalize}\t#{process}"
  task task.to_sym do
    print "[#{type}] Running\t:#{task}\t<#{process}>..."
    system(command_template % command)
  end
end
