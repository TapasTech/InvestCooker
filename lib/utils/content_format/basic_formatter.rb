# ContentFormat::BasicFormatter Formatter 的通用接口
module Utils
  module ContentFormat
    class BasicFormatter
      attr_accessor :content

      def initialize(content)
        @content = content
      end

      def self.format(content, &block)
        formatter = new(content)
        block.call(formatter)
        formatter.formatted_content
      end

      def formatted_content
        fail 'Needs Implementation'
      end

      def content
        @content || ''
      end
    end
  end
end
