######
# 一个实例只处理一个请求 及其 重试
######
module InvestCooker
  module YICAI
    class PushClient

      def initialize(type:, data:, retry_time: 3)
        @type       = type
        @data       = data
        @request_number = 0
        @retry_time = retry_time
      end

      def request(method: :post)
        @request_number += 1
        args = [method, url, request_json, {content_type: :json, accept: :json}]
        @response =
          RestClient.send(*args) do |response| # 这里用 block 是因为要跳过 RestClient 遇到非 200 系列 HTTP 状态码抛出的异常
            puts "YICAI:#{@request_number}:#{response.body}"
            response
          end
        handle_response_with_retry
        request_success?
      end

      # 覆盖上面的方法，使用 formdata, 由于很有可能再改回去，所以上面的保留
      def request(method: :post)
        @request_number += 1
        args = [method, url, @data.as_json]
        @response =
          RestClient.send(*args) do |response| # 这里用 block 是因为要跳过 RestClient 遇到非 200 系列 HTTP 状态码抛出的异常
            puts "YICAI:#{@request_number}:#{response.body}"
            response
          end
        handle_response_with_retry
        request_success?
      end

      private

      def request_json
        Oj.dump @data.as_json
      end

      def request_again
        sleep 5
        request
      end

      def handle_response_with_retry
        if request_success? || @request_number >= @retry_time
          record_request
        else
          request_again
        end
      end

      def request_success?
        message = @response.body if @response.code == 200
        message && message.to_s == '1'
      end

      def record_request
        copy_of_data = @data.clone.as_json

        InvestCooker::YICAI::RequestRecord.create \
          data:     copy_of_data,
          response: @response.body
      end

      def url
        Settings.yicai[@type].url
      end
    end
  end
end
