module InvestCooker
  module GLI
    class Client
      def initialize(time=Time.now)
        @folder = time.strftime('%Y%m%d')
        @target_path = File.join(Settings.glidata.target_path, @folder)
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
        $gli_sftp_pool.with { |sftp| block.call(sftp) }
      end
    end
  end
end
