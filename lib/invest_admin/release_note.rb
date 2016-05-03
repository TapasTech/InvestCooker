module InvestAdmin
  class ReleaseNote
    include Mongoid::Document
    include Mongoid::Timestamps

    field :version, type: String
    field :note,    type: String
  end
end
