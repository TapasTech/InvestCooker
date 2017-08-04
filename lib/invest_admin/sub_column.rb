module InvestAdmin
  class SubColumn
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
    field :parent_value, type: String
    field :parent_name,  type: String

    def parent
      return if parent_value.blank?

      {
        name: parent_name,
        value: parent_value
      }
    end
  end
end
