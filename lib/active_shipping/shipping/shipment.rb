module ActiveMerchant
  module Shipping
    class Shipment
      attr_accessor :number, :price, :tracking, :errors, :shipper, :payer,
        :origin, :destination, :service, :labels, :packages

      def initialize(attributes = {})
        @number = attributes[:number]
        @price = attributes[:price]
        @tracking = attributes[:tracking]
        @errors = attributes[:errors]
        @shipper = attributes[:shipper]
        @payer = attributes[:payer]
        @origin = attributes[:origin]
        @destination = attributes[:destination]
        @packages = attributes[:packages]
        @service = attributes[:service]
        @attributes = attributes
        @labels = []
      end

      def [](name)
        @attributes.try(:[], name)
      end
    end
  end
end
