require File.dirname(__FILE__) + '/../test_helper'

class EndiciaTest < Test::Unit::TestCase
  def setup
    @packages = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier = Endicia.new(fixtures(:endicia))
  end

  def test_buy_shipping_labels
    origin = @locations[:real_google_as_commercial]
    shipper = origin.dup
    shipper.number = '123456'
    shipper.passphrase = 'abcdef'
    shipper.attention = 'foobar'
    destination = @locations[:beverly_hills]
    packages = [@packages[:just_ounces], @packages[:chocolate_stuff]]
    shipment = @carrier.buy_shipping_labels(shipper, origin, destination, packages, :test => true, :shipment_number => '987654')
    assert shipment.errors.empty?
    assert_equal shipment.packages.length, shipment.labels.length
  end

  def test_change_passphrase
    shipper = @locations[:real_google_as_commercial].dup
    shipper.number = '123456'
    shipper.passphrase = 'abcdef'
    @carrier.change_passphrase(shipper)
    assert_not_equal 'abcdef', shipper.passphrase
  end
end
