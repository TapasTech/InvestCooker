module InvestCooker
  module CBN
    class Client

      def initialize(time=TIME_ZONE.call.now)
        @folder = time.strftime('%Y%m%d'.freeze)
        @source = File.join(Settings.glidata.target_path, @folder)
      end

      # 根据文件名读取文件的第一行为字符串，并转换成 UTF-8
      # 因为聚源的 json 文件只有一行，所以没有问题
      # @return hash_of_json_file
      def read(file_name)
        file_str =
          connection do |sftp|
            sftp.file.open(file_path(file_name), "r") { |f| f.gets }
          end
        Oj.load file_str, symbol_keys: true
      end

      REGEXP_JSON_FILE = /\.json$/.freeze

      # 读取当天文件夹下所有 json 文件名
      # @return list_of_file_names
      def list(page=nil, per=nil, &filter=->(_) { true })
        files =
          connection { |sftp| sftp.dir.entries(@source) }
            .select { |file| file.name =~ REGEXP_JSON_FILE }
            .select(&filter)
            .sort_by { |file| file.attributes.mtime }
            .reverse

        Kaminari.paginate_array(files).page(page).per(per)
      end

      private

      def file_path(file_name)
        File.join(@source, file_name)
      end

      def connection(&block)
        result = nil
        $gli_sftp_pool.with { |sftp| result = block.call(sftp) }
        result
      end
    end
  end
end
