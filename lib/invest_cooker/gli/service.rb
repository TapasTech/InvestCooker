module InvestCooker
  module GLI
    class Service

      def initialize(client=nil)
        @client    = client || InvestCooker::GLI::Client.new(TIME_ZONE.call.now)
        @date_str  = @client.date.strftime('%Y%m%d')
        @redis_key = "glidata:#{@date_str}"
      end

      # 从聚源文件夹读取当天的文件
      def read
        read_fresh_files do |file_name, date|
          ::GLI::ReadDataJob.perform_later file_name, date
        end
      end

      def read_file_data(file_name, logger)
        content_hash = Oj.load(@client.read(file_name), symbol_keys: true)
        content_hash[:data] && content_hash[:data][0] || {}
      rescue => e
        logger.info " Read fail (#{file_name})"
        raise e
      end

      def read_fresh_files
        setup_redis_key_expire_time

        # 记录已读过的文章
        file_names = fresh_file_names
        $redis_gli.sadd @redis_key, file_names if file_names.present?

        # 读入文件的时候乱序一下，一定程度上避免连续两篇相同文章入库
        file_names.shuffle.each do |file_name|
          yield file_name, @date_str
        end
      end

      def read_all_files
        @client.file_names.each do |file_name|
          yield file_name, @date_str
        end
      end

      private

        # 今天已经读取过的文件名
        def old_file_names
          $redis_gli.smembers @redis_key
        end

        # 今天还未读取的文件名
        def fresh_file_names
          @client.file_names - old_file_names
        end

        # Expire time's key after 2 days.
        def setup_redis_key_expire_time
          while (key_status = $redis_gli.ttl(@redis_key)) < 0
            case key_status
            when -2
              $redis_gli.sadd @redis_key, ""
            when -1
              $redis_gli.expire @redis_key, 2.days.to_i
            end
          end
        end
    end
  end
end
