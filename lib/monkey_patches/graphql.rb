GraphQL::Field.class_exec do
  # 为了实现动态的 fields
  def type
    @clean_type = begin
      ensure_defined
      GraphQL::BaseType.resolve_related_type(@dirty_type)
    end
  end
end

# monkey patch to support error handling

GraphQL::Relay::Mutation.class_exec do
  class << self
    define_with_error_handling = Module.new do
      def define(&block)
        super do |config|
          return_field :error, ErrorType, '错误信息'
          config.instance_eval(&block)
        end
      end
    end

    prepend define_with_error_handling
  end

  def resolve=(proc = nil, service: nil, action: nil)
    @resolve_proc =
      lambda do |inputs, ctx|
        begin
          inputs = inputs.to_h.deep_symbolize_keys
          if proc.present?

            proc.call(inputs, ctx)

          elsif service.name =~ /Service/

            params = inputs.merge(current_editor: ctx[:current_editor],
                                  controller:     ctx[:controller])

            service_instance = service.new(ActionController::Parameters.new(params))

            service_instance.serve(action)

            service_instance.instance_variable_names.select { |name| name != '@action_name' }.map do |name|
              [name[1..-1].to_sym, service_instance.instance_variable_get(:"#{name}")]
            end.to_h

          end
        rescue => e
          { error: e }
        end
      end
  end
end

GraphQL::Relay::Mutation::Result.class_exec do
  def method_missing(name, *_args)
    result[name]
  end
end

GraphQL::Relay::Query = GraphQL::Relay::Mutation
