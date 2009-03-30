module ActiveMerchant
  module Shipping
    class ShipmentAcceptResponse < Response
      attr_accessor :label, :tracking_number

      def initialize(success, message, params, options)
        super
      end
    end
  end
end
