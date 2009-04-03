module ActiveMerchant
  module Shipping
    class BogusCarrier < Carrier
      cattr_reader :name
      @@name = "Bogus Carrier"

      def find_rates(origin, destination, packages, options = {})
        origin = Location.from(origin)
        destination = Location.from(destination)
        packages = Array(packages)
      end

      def buy_shipping_labels(shipper, origin, destination, packages, options = {})
        tracking = Array.new(9) { rand(9) }.join
        Shipment.new(
          :shipper => shipper,
          :origin => origin,
          :destination => destination,
          :packages => Array(packages),
          :tracking => tracking,
          :labels => packages.map {|p| Label.new(:tracking => tracking) }
        )
      end
    end
  end
end
