module InvestAdmin
  class ForbiddenComposeOrganization
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String
  end
end
