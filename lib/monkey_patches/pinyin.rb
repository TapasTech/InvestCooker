module PinYin
  class << self
    of_string_with_replace_v = Module.new do      
      super(*args, &block).map { |str| str.gsub("\u0308u", 'v') }
    end

    prepend of_string_with_replace_v
  end
end
