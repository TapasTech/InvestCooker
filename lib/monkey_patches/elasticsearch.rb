module Elasticsearch::Model::Adapter::Mongoid
  module Callbacks
    def self.included(base)
      # Add validation callback.
      # Target may decide if it should be indexed.
      base.send(:define_method, :elasticsearch_index_validation) { true }

      {
        :create  => :index,
        :update  => :index,
        :destroy => :delete
      }.each_pair do |after_action, es_action|
        base.send("after_#{after_action}") do |document|
          document.__elasticsearch__.send("#{es_action}_document") if document.elasticsearch_index_validation
        end
      end
    end
  end

  module Importing
    def __transform
      lambda { |a|  {index:{ _id: a.id.to_s, data: a.__elasticsearch__.as_indexed_json}} }
    end

    def __find_in_batches(options={}, &block)
      batch_size = options[:batch_size] || 1_000
      scope      = options[:scope]      || :all

      collection = public_send(scope)

      if defined? ProgressBar
        bar = ProgressBar.new(collection.count / batch_size)
      else
        bar = nil
      end

      collection.no_timeout.each_slice(batch_size) do |items|
        yield items
        bar&.increment!
      end
    end
  end
end

class Elasticsearch::Model::Indexing::Mappings
  def to_hash
    { @type.to_sym => @options.merge( properties: @mapping.as_json(except: :as) ) }
  end
end

module Elasticsearch::Model::Serializing::InstanceMethods

  def as_indexed_json(options={})
    build_indexed_json(
      target.class.mappings.instance_variable_get(:@mapping),
      target,
      {id: target.id.to_s}
    ).as_json(options.merge root: false)
  end

private

  def build_indexed_json(mappings, model, json)
    return json unless model.respond_to? :[]

    if model.kind_of? Array
      build_array_json(mappings, model, json)
    else
      build_hash_json(mappings, model, json)
    end

    json
  end

  def build_array_json(mappings, model, json)
    return json unless model.respond_to?(:[]) && json.kind_of?(Array)

    model.each do |elem|
      elem_json = if elem.kind_of? Array then [] else {} end
      json << elem_json
      build_indexed_json(mappings, elem, elem_json)
    end
  end

  def build_hash_json(mappings, model, json)
    return json unless model.respond_to?(:[]) && json.kind_of?(Hash)

    mappings.each_pair do |field, option|

      # Custom transformer
      if option.has_key?(:as) && option[:as].kind_of?(Proc)
        json[field] = target.instance_exec(get_field(model, field), &option[:as])

      # A nested field
      elsif option.has_key?(:properties)
        json[field] = if get_field(model, field).kind_of? Array then [] else {} end
        build_indexed_json(option[:properties], get_field(model, field), json[field])

      # Normal case
      else
        json[field] = get_field(model, field)
      end
    end
  end

  def get_field(model, field_name)
    model.try(:[], field_name) || model.try(field_name)
  end
end
