module ActiveMerchant
  module Shipping
    class Shipment
      attr_accessor :number, :price, :tracking, :shipper, :payer,
        :origin, :destination, :service, :labels, :packages, :errors,:value

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
        @value = attributes[:value]
        @attributes = attributes
        @errors = []
        @labels = []
        @log = []
      end

      def [](name)
        @attributes.try(:[], name)
      end

      def []=(name, value)
        @attributes.try(:[]=, name, value)
      end

      def log(value = nil)
        if value
          @log << value
        else
          @log
        end
      end
    end
  end
end
