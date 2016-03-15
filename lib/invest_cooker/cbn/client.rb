module InvestCooker
  module CBN
    class Client
      def initialize(time=TIME_ZONE.call.now)
        @folder = time.strftime('%Y%m%d')
        @source = File.join(Settings.glidata.target_path, @folder)
      end

      # 根据文件名读取文件的第一行为字符串，并转换成 UTF-8
      # 因为聚源的 json 文件只有一行，所以没有问题
      # @return hash_of_json_file
      def read(file_name)
        line = ''
        connection do |sftp|
          sftp.file.open(File.join(@source, file_name), "r") do |f|
            line = f.gets
          end
        end
        file_str = line
        Oj.load file_str, symbol_keys: true
      end

      # 读取当天文件夹下所有 json 文件名
      # @return list_of_file_names
      def list(page, per)
        list = []
        connection do |sftp|
          list = sftp.dir.entries(@source)
        end
        list = list.select { |file| file.name =~ /\.json$/ }
        list = list.sort_by { |file| file.attributes.mtime }.reverse

        Kaminari.paginate_array(list).page(page).per(per)
      end

      private

      def connection(&block)
        $gli_sftp_pool.with { |sftp| block.call(sftp) }
      end
    end
  end
end
