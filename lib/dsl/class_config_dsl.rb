concern :ClassConfigDSL do
  included do
    class << self
      def add_config(name)
        define_singleton_method(name) do |value=nil|
          if value.nil?
            self.instance_variable_get(:"@#{name}")
          else
            self.instance_variable_set(:"@#{name}", value)
          end
        end

        define_method(name) do
          self.class.send(name)
        end
      end
    end
  end
end
