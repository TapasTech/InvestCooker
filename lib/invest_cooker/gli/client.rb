module InvestCooker
  module GLI
    class Client
      def initialize(time=TIME_ZONE.call.now)
        @folder = time.strftime('%Y%m%d'.freeze)
        @source_path = File.join(Settings.glidata.source_path, @folder)
        @target_path = File.join(Settings.glidata.target_path, @folder)
      end

      def date
        @date ||= TIME_ZONE.call.parse(@folder)
      end

      # 根据文件名读取文件的第一行为字符串，并转换成 UTF-8
      # 因为聚源的 json 文件只有一行，所以没有问题
      def read(file_name)
        connection do |sftp|
          sftp.file.open(File.join(@source_path, file_name), 'r'.freeze) { |f| f.gets }
        end.force_encoding("GB18030".freeze).encode("UTF-8".freeze)
      end

      REGEXP_JS_FILE = /\.js$/.freeze

      # 读取当天文件夹下所有 js 文件名
      def file_names
        connection { |sftp| sftp.dir.entries(@source_path).map(&:name) }
          .select { |file_name| file_name =~ REGEXP_JS_FILE }
      end

      MKDIR = -> (sftp, path) { Try { sftp.mkdir! path } }.freeze

      def write(file_name, file_str, valid=true)

        connection do |sftp|
          # 创建相关文件夹
          MKDIR.(sftp, path = @target_path)
          MKDIR.(sftp, path = File.join(path, 'invalid_incoming'.freeze)) unless valid

          # 写入文件
          sftp.file.open(File.join(path, file_name), 'w'.freeze) do |f|
            f.puts file_str.force_encoding('ASCII-8BIT'.freeze)
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
