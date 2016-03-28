######
# 一个实例只处理一个请求
######
module InvestCooker
  module MAYI
    class Client
      def initialize(api:, action:, data:, retry_time: 1)
        @api        = api.freeze
        @action     = action.freeze
        @retry_time = retry_time.freeze
        @data       = data
        @request_number = 0
      end

      def request(method: :post)
        @request_number += 1
        args = [method, url, request_json, {content_type: :json, accept: :json}]
        @response =
          RestClient.send(*args) do |response| # 这里用 block 是因为要跳过 RestClient 遇到非 200 系列 HTTP 状态码抛出的异常
            puts "MAYI:#{method}:#{@api}:#{@action}:#{@request_number}:#{response.body}"
            response
          end
        handle_response_with_retry
        request_success?
      end

      private

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
        message = Oj.load(@response.body, symbol_keys: true) if @response.code == 200
        message && message[:respCode] == 'success'
      rescue Oj::ParseError
        false
      end

      def record_request
        copy_of_data = @data.clone.as_json

        if @api == 'push'
          copy_of_data.delete('images')
        end

        if @api == 'banner'
          copy_of_data['banners'].each do |banner|
            banner.delete('image')
          end
        end

        InvestCooker::MAYI::RequestRecord.create \
          trans_id: trans_id,
          api:      @api,
          action:   @action,
          data:     copy_of_data,
          response: @response.body.force_encoding("GB18030").encode("UTF-8")
      end

      def request_json
        @request_json ||= gbk_json({
          'mac'     => mac,
          'transId' => trans_id,
          'action'  => @action,
          'data'    => @data
        })
      end

      def url
        @url ||= Settings.mayi.urls.send(@api).send(@action)
      end

      def trans_id(now=Time.zone.now)
        @trans_id ||= "#{now.strftime('%Y%m%d%H%M%S')}#{now.nsec}".ljust(23, '0')
      end

      def mac
        @mac ||= Utils::RSA.generate_base64_signiture gbk_json(@data)
      end

      def gbk_json(hash)
        Oj.dump(hash.as_json).encode('GBK')
      end
    end
  end
end
