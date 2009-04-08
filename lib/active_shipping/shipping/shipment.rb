module ActiveMerchant
  module Shipping
    class Shipment
      attr_accessor :number, :price, :tracking, :shipper, :payer,
        :origin, :destination, :service, :labels, :packages, :errors

      def initialize(attributes = {})
        @number = attributes[:number]
        @price = attributes[:price]
        @tracking = attributes[:tracking]
        @shipper = attributes[:shipper]
        @payer = attributes[:payer]
        @origin = attributes[:origin]
        @destination = attributes[:destination]
        @packages = attributes[:packages]
        @service = attributes[:service]
        @attributes = attributes
        @errors = []
        @labels = []
      end

      def [](name)
        @attributes.try(:[], name)
      end

      def []=(name, value)
        @attributes.try(:[]=, name, value)
      end
    end
  end
end
