require 'mongoid'

module InvestCooker
  module MAYI
    class RequestRecord
      include Mongoid::Document
      include Mongoid::Timestamps

      field :trans_id,   type: String
      field :api,        type: String
      field :action,     type: String
      field :data,       type: Hash,   default: ->{Hash.new}
      field :response,   type: String

      index({updated_at: -1}, background: true)
    end
  end
end
