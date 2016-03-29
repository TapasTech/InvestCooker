module InvestCooker
  module YCWB
    class Client
      URL = 'http://app.yicai.com/srv/ali.ashx'

      # 测试哪些文章列表是空的
      # 这个方法给开发人员测试使用
      def self.check_list
        client = self.new
        ::YCWB::ReadListJob::COLUMNS_MAPPING.keys.select do |cid|
          empty = client.list(cid, pagesize: 1)['News'].blank?
          puts "#{cid} => #{empty}"
          sleep 1
          empty
        end
      end

      def list(cid, pagesize: 100, page: 1)
        @params = {
          command: 'list',
          cid: cid.to_i,
          pagesize: pagesize,
          page: page
        }
        @param_keys = [:command, :cid, :pagesize, :page]
        request
      end

      def read(nid)
        @params = {
          command: 'read',
          nid: nid.to_i
        }
        @param_keys = [:command, :nid]
        request
      end

      private

      attr_reader :params, :param_keys

      def request
        retry_time = 0
        sleep_time = rand(10)
        begin
          response = RestClient.post(URL, request_params).body
          Oj.load response
        rescue => e
          puts e
          retry_time += 1
          sleep sleep_time # 大致将并发分成 10 份来避开网络延迟导致的请求失败
          retry if retry_time < 5
        end
      end

      def request_params
        Hash[param_keys.map { |k| [k, params[k]] }].merge({check: check})
      end

      # MD5 校验码
      def check
        Digest::MD5.hexdigest "#{param_keys.map {|key| params[key]}.join}#{ENV['HUGO_INVEST_SERVER_YCWB_KEY']}"
      end
    end
  end
end
