require File.dirname(__FILE__) + '/../../test_helper'

class EndiciaTest < Test::Unit::TestCase
  def setup
    @packages  = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier = Endicia.new(:partner_id => '123456')
  end

  def test_build_change_passphrase_request
    shipper = @locations[:real_google_as_commercial]
    shipper.number = '123456'
    shipper.passphrase = 'foobar'
    request = @carrier.send(:build_change_passphrase_request, shipper)
    assert_nothing_raised do
      REXML::Document.new(request)
    end
  end
end
