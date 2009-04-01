module ActiveMerchant
  module Shipping
    class Shipment
      attr :number, :labels

      def initialize(options = {})
        @number = options[:number]
        @labels = []
      end
    end
  end
end
