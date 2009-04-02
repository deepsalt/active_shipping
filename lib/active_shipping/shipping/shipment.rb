module ActiveMerchant
  module Shipping
    class Shipment
      attr_accessor :number
      attr_reader :labels

      def initialize(options = {})
        @number = options[:number]
        @labels = []
      end
    end
  end
end
