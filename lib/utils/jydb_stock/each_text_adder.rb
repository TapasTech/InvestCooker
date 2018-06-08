module Utils
  module JYDBStock
    class EachTextAdder
      attr_accessor :content

      def initialize(content)
        @added = []
        @content = content
      end

      def add_one_stock_code(name, codes, skip)
        modify_each_text! { |t| skip_added(name) { |checker|
          content_before = t.content.clone
          content_after  = t.content.clone
          Adder.new(content_after, name, codes, skip).add_one_stock_code
          t.replace(content_after)

          content_before != content_after
        } }
      end

      private

      def skip_added(name)
        return if @added.include?(name)
        @added << name if yield
      end

      def modify_each_text!
        doc = Nokogiri::HTML(@content)
        doc.search('//text()').to_a.each { |t| yield t }
        @content = doc.css('body').inner_html.gsub("\n", '')
      end
    end
  end
end
