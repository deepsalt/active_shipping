module ActiveMerchant
  module Shipping
    class Shipment
      attr_accessor :number, :price, :tracking
      attr_reader :labels

      def initialize(options = {})
        @number = options[:number]
        @price = options[:price]
        @tracking = options[:tracking]
        @labels = []
      end
    end
  end
end
