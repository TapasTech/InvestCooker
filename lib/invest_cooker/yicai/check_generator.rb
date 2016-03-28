module InvestCooker
  module YICAI
    class CheckGenerator

      def self.generate_news_check(information)
        generate_check([
          information['title'],
          information['source'],
          information['link'],
          information['author']
        ].join)
      end

      def self.generate_live_check(information)
        generate_check([
          information['title'],
          information['content'],
          information['images'],
          information['region'],
          information['category'],
          information['important']
        ].join)
      end

      def self.generate_check(str)
        Digest::MD5.hexdigest("#{str}#{app_key}")
      end

      def self.app_key
        ENV['HUGO_INVEST_SERVER_YICAI_APP_KEY']
      end
    end
  end
end
