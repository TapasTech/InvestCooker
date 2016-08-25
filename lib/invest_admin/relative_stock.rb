# 相关股票
# codes 指代的股票属于同一支股票
module InvestAdmin
  class RelativeStock
    include Mongoid::Document

    field :codes, type: Array, default: -> { [] }
    validates :codes, presence: true
    index codes: 1

    class << self
      def code_hash
        hash = {}
        all.pluck(:codes).each do |codes|
          codes.each do |code|
            hash[code] = codes
          end
        end
        hash
      end

      private

      def init!
        SpecialStockMapping.pluck(:codes).uniq.each do |codes|
          self.find_or_create_by(codes: codes)
        end
      end
    end
  end
end
