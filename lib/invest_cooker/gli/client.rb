module InvestCooker
  module GLI
    class Client

      # 目前项目的时间有两种
      # Rails 中使用 Time.zone.now
      # Invest 的非 Rails 项目使用 Application.time_zone.now
      def self.time_zone_for_rails_or_application
        return Time.zone             if const_defined?('Rails')
        return Application.time_zone if const_defined?('Application')
        Time
      end

      TIME_ZONE = time_zone_for_rails_or_application

      def initialize(time=TIME_ZONE.now)
        @folder = time.strftime('%Y%m%d')
        @source_path = File.join(Settings.glidata.source_path, @folder)
        @target_path = File.join(Settings.glidata.target_path, @folder)
      end

      def date
        @date ||= TIME_ZONE.parse(@folder)
      end

      # 根据文件名读取文件的第一行为字符串，并转换成 UTF-8
      # 因为聚源的 json 文件只有一行，所以没有问题
      def read(file_name)
        connection do |sftp|
          line = ''
          result =
            sftp.file.open(File.join(@source_path, file_name), "r") do |f|
              line = f.gets
            end
          line
        end.force_encoding("GB18030").encode("UTF-8")
      end

      # 读取当天文件夹下所有 js 文件名
      def file_names
        connection do |sftp|
          sftp.dir.entries(@source_path).map(&:name)
        end.select { |file_name| file_name =~ /\.js$/ }
      end

      def write(file_name, file_str, valid=true)

        mkdir = -> (sftp, path) { Try { sftp.mkdir! path } }

        connection do |sftp|
          # 创建相关文件夹
          mkdir.(sftp, path = @target_path)
          mkdir.(sftp, path = File.join(path, 'invalid_incoming')) unless valid

          # 写入文件
          sftp.file.open(File.join(path, file_name), 'w') do |f|
            f.puts file_str.force_encoding("ASCII-8BIT")
          end
        end
      end

      private

      def connection(&block)
        result = nil
        $gli_sftp_pool.with { |sftp| result = block.call(sftp) }
        result
      end
    end
  end
end
