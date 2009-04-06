require 'active_shipping/shipping/carriers/bogus_carrier'
require 'active_shipping/shipping/carriers/ups'
require 'active_shipping/shipping/carriers/usps'
require 'active_shipping/shipping/carriers/fedex'
require 'active_shipping/shipping/carriers/shipwire'
require 'active_shipping/shipping/carriers/endicia'

module ActiveMerchant
  module Shipping
    module Carriers
      class <<self
        def all
          [BogusCarrier, UPS, USPS, FedEx, Endicia]
        end
      end
    end
  end
end
