concern :MongoidSample do
  included do
    class << self
      def sample
        self.skip(rand(self.count)).limit(1).first
      end
    end
  end
end
