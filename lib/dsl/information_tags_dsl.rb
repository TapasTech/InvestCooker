concern :InformationTagsDSL do
  included do
    class << self
      # 提供一个方法判断是否应该标记 information_tag
      def information_tag(name, &block)
        @information_tags ||= {}
        @information_tags[name] = block
      end

      def information_tags
        @information_tags
      end

      # 提供一个方法加入一组 informantion_tags
      def information_tag_merge(&block)
        @information_tag_merge ||= []
        @information_tag_merge << block
        @information_tag_merge
      end
    end

    def information_tags
      tags = []

      self.class.information_tag_merge.each do |block|
        tags += block.call(self)
      end

      self.class.information_tags.each do |name, block|
        tags << name if block.call(self)
      end

      tags.uniq
    end

    def information_tags_include?(name)
      self.class.information_tags[name]&.call(self)
    end
  end
end
