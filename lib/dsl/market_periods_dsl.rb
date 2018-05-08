# 当前时间属于股票交易的不同阶段，处理不同的逻辑
# Example
# class Market
#   include MarketPeriodDSL
#
#   information(:hello) do
#     market_open do
#       "hello, market is opening #{now}"
#     end
#
#     middle_rest do
#       "hello, market is middle resting #{now}"
#     end
#
#     market_close do
#       "hello, market is closed #{now}"
#     end
#   end
# end
#
# Market.new.hello

concern :MarketPeriodDSL do
  included do
    attr_reader :now

    class << self
      include ClassModule
    end
  end

  def initialize(now=Time.zone.now)
    @now = now
  end

  module ClassModule
    PERIODS = %w(market_close market_open middle_rest)

    def information(name)
      @informations ||= {}
      @informations[name] ||= {}

      methods = @informations[name]

      define_method(name) do
        start     = now.change(hour: 9,  min: 30)
        ending    = now.change(hour: 15, min: 0)
        mid_start = now.change(hour: 11, min: 30)
        mid_end   = now.change(hour: 13, min: 0)

        if !now.between?(start, ending)
          instance_exec(&methods[:market_close])

        elsif now.between?(mid_start, mid_end)
          instance_exec(&methods[:middle_rest])

        else
          instance_exec(&methods[:market_open])
        end
      end

      PERIODS.each do |on|
        define_singleton_method(on) do |&block|
          @informations[name][on.to_sym] = block
        end
      end

      yield if block_given?

      class << self
        PERIODS.each(&method(:remove_method))
      end
    end
  end
end
