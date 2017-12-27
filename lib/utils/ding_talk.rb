module Utils
  class DingTalk

    def self.send_markdown_message(url:, title:, text:)
      Service.new(url).send_markdown_message(title: title, text: text)
    end

    class Service
      attr_accessor :url

      def initialize(url)
        self.url = url
      end

      def send_markdown_message(title:, text:)
        post({
          msgtype: 'markdown',
          markdown: {
            title: title,
            text: text
          }
        })
      end

      def post(hash)
        data = Oj.dump(hash.as_json)
        RestClient::Resource.new(url, verify_ssl: false).post(data, {content_type: :json})
      end
    end
  end
end
