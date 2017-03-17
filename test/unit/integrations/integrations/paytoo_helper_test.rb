require 'test_helper'

class PaytooHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Paytoo::Helper.new('order-500','cody@example.com', :amount => 500, :currency => 'USD')
    @url = 'http://example.com'
  end

  def test_basic_helper_fields

    assert_field 'amount', '500'
    assert_field 'description', 'order-500'
  end

  def test_customer_fields
    @helper.name_first ='Cody'
    @helper.name_last ='Fauser'
    @helper.email_address ='cody@example.com'

    # assert_field 'name_first', 'Cody'
    # assert_field 'name_last', 'Fauser'
    # assert_field '', 'cody@example.com'
  end

  def test_cancel_return_url
    @helper.cancel_return_url = @url
    #assert_field 'cancel_return_url', @url
  end

  def test_address_mapping
    @helper.billing_address = '1 My Street'


  end

end
