class DebugLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"
  end
end

debug_logfile = File.open("#{Rails.root}/log/debug.log", 'a')
debug_logfile.sync = true
$debug_logger = DebugLogger.new(debug_logfile)
