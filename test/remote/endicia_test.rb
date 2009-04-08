require File.dirname(__FILE__) + '/../test_helper'

class EndiciaTest < Test::Unit::TestCase
  def setup
    @packages = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier = Endicia.new(fixtures(:endicia))
    @shipper = @locations[:real_google_as_commercial].dup
    @shipper.number = '123456'
    @shipper.passphrase = 'abcdef'
    @shipper.attention = 'Foo Bar'
  end

  def test_buy_shipping_labels
    origin = @locations[:real_google_as_commercial]
    destination = @locations[:beverly_hills]
    packages = [@packages[:just_ounces], @packages[:chocolate_stuff]]
    shipment = @carrier.buy_shipping_labels(@shipper, origin, destination, packages, :test => true, :shipment_number => '987654')
    assert shipment.errors.empty?
    assert_equal shipment.packages.length, shipment.labels.length
  end

  def test_change_passphrase
    old = @shipper.passphrase
    @carrier.change_passphrase(@shipper)
    assert_not_equal old, @shipper.passphrase
  end

  def test_buy_postage
    assert_nothing_raised do
      @carrier.buy_postage(@shipper, Money.new(5000))
    end
  end

  def test_find_rates
    origin = @locations[:real_google_as_commercial]
    destination = @locations[:beverly_hills]
    packages = [@packages[:just_ounces], @packages[:chocolate_stuff]]
    shipment = Shipment.new(:origin => origin, :destination => destination, :packages => packages)
    rates = @carrier.find_rates(@shipper, shipment, 'Priority')
    assert_equal rates.keys, ['Priority']
    assert rates['Priority'].cents > 0
  end
end
