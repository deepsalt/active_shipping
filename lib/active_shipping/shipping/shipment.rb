module ActiveMerchant
  module Shipping
    class Shipment
      attr :labels

      def initialize
        @labels = []
      end
    end
  end
end
