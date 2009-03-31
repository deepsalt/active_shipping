module ActiveMerchant
  module Shipping
    class Shipper
      attr_reader :name, :number

      def initialize(options = {})
        @name = options[:name]
        @number = options[:number]
      end
    end
  end
end
