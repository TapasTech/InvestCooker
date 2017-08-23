module InvestAdmin
  class DefaultPrivilege
    include Mongoid::Document
    include Mongoid::Timestamps
    include TeamScope

    field :name, type: String
    field :privileges, type: Array, default: -> { [] }
  end
end
