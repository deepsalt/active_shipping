require File.dirname(__FILE__) + '/../test_helper'

class ShipperTest < Test::Unit::TestCase
  include ActiveMerchant::Shipping

  def setup
    @shipper = Shipper.new(:name => 'Foo', :number => '23')
  end

  def test_name
    assert_equal 'Foo', @shipper.name 
  end

  def test_number
    assert_equal '23', @shipper.number
  end
end
