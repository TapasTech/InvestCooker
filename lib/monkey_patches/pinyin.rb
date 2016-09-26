module PinYin
  class << self
    of_string_with_replace_v = Module.new do
      def of_string(*args, &block)
        super(*args, &block).map { |str| str.gsub("\u0308u", 'v') }
      end
    end

    prepend of_string_with_replace_v
  end
end
