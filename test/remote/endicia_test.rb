require File.dirname(__FILE__) + '/../test_helper'

class EndiciaTest < Test::Unit::TestCase
  def setup
    @packages = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier = Endicia.new(fixtures(:endicia))
  end

  def test_buy_shipping_labels
    origin = @locations[:real_google_as_commercial]
    destination = @locations[:beverly_hills]
    packages = [@packages[:just_ounces], @packages[:chocolate_stuff]]
    shipment = @carrier.buy_shipping_labels(origin, origin, destination, packages, :test => true)
    assert_equal packages.length, shipment.labels.length
  end
end
