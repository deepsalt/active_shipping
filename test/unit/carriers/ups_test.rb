require File.dirname(__FILE__) + '/../../test_helper'

class UPSTest < Test::Unit::TestCase
  
  def setup
    @packages  = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier   = UPS.new(
                   :key => 'key',
                   :login => 'login',
                   :password => 'password'
                 )
    @tracking_response = xml_fixture('ups/shipment_from_tiger_direct')
  end
  
  def test_initialize_options_requirements
    assert_raises(ArgumentError) { UPS.new }
    assert_raises(ArgumentError) { UPS.new(:login => 'blah', :password => 'bloo') }
    assert_raises(ArgumentError) { UPS.new(:login => 'blah', :key => 'kee') }
    assert_raises(ArgumentError) { UPS.new(:password => 'bloo', :key => 'kee') }
    assert_nothing_raised { UPS.new(:login => 'blah', :password => 'bloo', :key => 'kee') }
  end
  
  def test_find_tracking_info_should_return_a_tracking_response
    @carrier.expects(:commit).returns(@tracking_response)
    assert_equal 'ActiveMerchant::Shipping::TrackingResponse', @carrier.find_tracking_info('1Z5FX0076803466397').class.name
  end
  
  def test_find_tracking_info_should_parse_response_into_correct_number_of_shipment_events
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal 8, response.shipment_events.size
  end
  
  def test_find_tracking_info_should_return_shipment_events_in_ascending_chronological_order
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal response.shipment_events.map(&:time).sort, response.shipment_events.map(&:time)
  end
  
  def test_find_tracking_info_should_have_correct_names_for_shipment_events
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal [ "BILLING INFORMATION RECEIVED",
                   "IMPORT SCAN",
                   "LOCATION SCAN",
                   "LOCATION SCAN",
                   "DEPARTURE SCAN",
                   "ARRIVAL SCAN",
                   "OUT FOR DELIVERY",
                   "DELIVERED" ], response.shipment_events.map(&:name)
  end
  
  def test_add_origin_and_destination_data_to_shipment_events_where_appropriate
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal '175 AMBASSADOR', response.shipment_events.first.location.address1
    assert_equal 'K1N5X8', response.shipment_events.last.location.postal_code
  end
  
  def test_response_parsing
    mock_response = xml_fixture('ups/test_real_home_as_residential_destination_response')
    @carrier.expects(:commit).returns(mock_response)
    response = @carrier.find_rates( @locations[:beverly_hills],
                                    @locations[:real_home_as_residential],
                                    @packages.values_at(:chocolate_stuff))
    assert_equal [ "UPS Ground",
                   "UPS Three-Day Select",
                   "UPS Second Day Air",
                   "UPS Next Day Air Saver",
                   "UPS Next Day Air Early A.M.",
                   "UPS Next Day Air"], response.rates.map(&:service_name)
    assert_equal [992, 2191, 3007, 5509, 9401, 6124], response.rates.map(&:price)
  end
  
  def test_xml_logging_to_file
    mock_response = xml_fixture('ups/test_real_home_as_residential_destination_response')
    @carrier.expects(:commit).times(2).returns(mock_response)
    RateResponse.any_instance.expects(:log_xml).with({:name => 'test', :path => '/tmp/logs'}).times(1).returns(true)
    response = @carrier.find_rates( @locations[:beverly_hills],
                                    @locations[:real_home_as_residential],
                                    @packages.values_at(:chocolate_stuff),
                                    :log_xml => {:name => 'test', :path => '/tmp/logs'})
    response = @carrier.find_rates( @locations[:beverly_hills],
                                    @locations[:real_home_as_residential],
                                    @packages.values_at(:chocolate_stuff))
  end
  
  def test_maximum_weight
    assert Package.new(150 * 16, [5,5,5], :units => :imperial).mass == @carrier.maximum_weight
    assert Package.new((150 * 16) + 0.01, [5,5,5], :units => :imperial).mass > @carrier.maximum_weight
    assert Package.new((150 * 16) - 0.01, [5,5,5], :units => :imperial).mass < @carrier.maximum_weight
  end

  def test_buy_shipping_labels
    @carrier.expects(:build_access_request).times(2).returns('')
    @carrier.expects(:commit).times(2)
    @carrier.expects(:save_request).times(2)
    @carrier.expects(:build_shipment_confirm_request).returns('')
    def @carrier.parse_shipment_confirm(shipment, response)
      shipment.price = Money.new(1)
      shipment
    end
    @carrier.expects(:build_shipment_accept_request).returns('')
    @carrier.expects(:parse_shipment_accept)
    shipment = @carrier.buy_shipping_labels(nil, nil, nil, nil)
    assert shipment.kind_of?(Shipment)
  end

  def test_build_shipment_confirm_request
    shipper = @locations[:real_google_as_commercial]
    shipper.number = '456'
    shipment = Shipment.new(
      :number => '123',
      :shipper => shipper,
      :payer => shipper,
      :origin => shipper,
      :destination => @locations[:beverly_hills],
      :packages => @packages.values
    )
    request = @carrier.send(:build_shipment_confirm_request, shipment)
    assert_nothing_raised do
      REXML::Document.new(request)
    end
  end

  def test_build_shipment_accept_request
    shipment = Shipment.new(
      :name => '123',
      :digest => 'foobar'
    )
    request = @carrier.send(:build_shipment_accept_request, shipment)
    assert_nothing_raised do
      REXML::Document.new(request)
    end
  end

  def test_parse_money
    element = REXML::Document.new('<Charge><MonetaryValue>5.23</MonetaryValue><CurrencyCode>USD</CurrencyCode></Charge>').root
    assert_equal Money.new(523, 'USD'), @carrier.send(:parse_money, element)
  end

  def test_parse_shipment_confirm
    response = xml_fixture('ups/ShipmentConfirmResponse')
    shipment = Shipment.new
    @carrier.send(:parse_shipment_confirm, shipment, response)
    assert_equal Money.new(11848), shipment.price
    assert shipment[:digest]
  end

  def test_parse_shipment_accept
    response = xml_fixture('ups/ShipmentAcceptResponse')
    shipment = Shipment.new
    @carrier.send(:parse_shipment_accept, shipment, response)
    assert_equal Money.new(11848), shipment.price
    assert_equal '1Z2220060292353829', shipment.tracking
    assert_equal shipment.labels.length, 1
    label = shipment.labels.first
    assert_equal '1Z2220060292353829', label.tracking
    assert label.image
  end
end
