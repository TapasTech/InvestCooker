# ContentFormat::BasicFormatter Formatter 的通用接口
module Utils
  module ContentFormat
    class BasicFormatter
      attr_accessor :content

      def initialize(content, options={})
        self.content = content
      end

      def self.format(content, options={}, &block)
        formatter = new(content, options)
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
