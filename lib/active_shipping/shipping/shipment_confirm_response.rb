module ActiveMerchant
  module Shipping
    class ShipmentConfirmResponse < Response
      attr_reader :label

      def initialize(success, message, params, options)
        super
      end
    end
  end
end
