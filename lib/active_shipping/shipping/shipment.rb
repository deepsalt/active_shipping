module ActiveMerchant
  module Shipping
    class Shipment
      attr_accessor :number, :price, :tracking, :errors
      attr_reader :labels

      def initialize(attributes = {})
        @number = attributes[:number]
        @price = attributes[:price]
        @tracking = attributes[:tracking]
        @errors = attributes[:errors]
        @attributes = attributes
        @labels = []
      end

      def [](name)
        @attributes.try(:[], name)
      end
    end
  end
end
