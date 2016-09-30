concern :Remember do
  included do
    class << self
      def remember(*method_names)
        methods_with_remember = Module.new do
          method_names.each do |method_name|
            define_method method_name do |*args|
              value = instance_variable_get("@#{method_name}")

              if value.blank?
                value = super(*args)
                instance_variable_set("@#{method_name}", value)
              end

              value
            end
          end
        end

        prepend methods_with_remember
      end
    end
  end
end
