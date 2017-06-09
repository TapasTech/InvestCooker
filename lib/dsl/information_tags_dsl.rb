concern :InformationTagsDSL do
  included do
    class << self
      def information_tag(name, &block)
        @information_tags ||= {}
        @information_tags[name] = block
      end

      def information_tags
        @information_tags
      end
    end

    def information_tags
      tags = []
      self.class.information_tags.each do |name, block|
        tags << name if block.call(self)
      end
      tags
    end

    def information_tags_include?(name)
      self.class.information_tags[name]&.call(self)
    end
  end
end
