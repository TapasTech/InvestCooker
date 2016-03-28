module InvestCooker
  module YICAI
    class RequestRecord
      include Mongoid::Document
      include Mongoid::Timestamps

      field :data,       type: Hash,   default: -> { Hash.new }
      field :response,   type: String
    end
  end
end
