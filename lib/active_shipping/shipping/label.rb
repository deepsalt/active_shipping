module ActiveMerchant
  module Shipping
    class Label
      attr_reader :tracking, :image
      def initialize(attributes = {})
        @tracking = attributes[:tracking]
        @image = attributes[:image]
      end
    end
  end
end
