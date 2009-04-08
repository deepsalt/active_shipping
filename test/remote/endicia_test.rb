require File.dirname(__FILE__) + '/../test_helper'

class EndiciaTest < Test::Unit::TestCase
  def setup
    @packages = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier = Endicia.new(fixtures(:endicia).merge('test' => true))
    @shipper = @locations[:real_google_as_commercial].dup
    @shipper.number = '123456'
    @shipper.passphrase = 'abcdef'
    @shipper.attention = 'Foo Bar'
    @shipment = Shipment.new(
      :shipper => @shipper,
      :origin => @locations[:real_google_as_commercial],
      :destination => @locations[:beverly_hills],
      :packages => [@packages[:just_ounces], @packages[:chocolate_stuff]],
      :number => '987654'
    )
  end

  def test_buy_shipping_labels
    @shipment.service = 'Priority'
    @carrier.buy_shipping_labels(@shipment)
    assert_equal @shipment.packages.length, @shipment.labels.length
  end

  def test_change_passphrase
    old = @shipper.passphrase
    @carrier.change_passphrase(@shipper)
    assert_not_equal old, @shipper.passphrase
  end

  def test_buy_postage
    @carrier.buy_postage(@shipper, Money.new(5000))
  end

  def test_find_rates
    rates = @carrier.find_rates(@shipment, 'Priority')
    assert_equal rates.keys, ['Priority']
    assert rates['Priority'].cents > 0
  end
end
