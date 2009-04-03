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

      def find_tracking_info(tracking, options = {})
        TrackingResponse.new(true, nil, nil, :tracking_number => tracking,
          :shipment_events => [ShipmentEvent.new('Delivered', Time.now, nil)])
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
