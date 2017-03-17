require 'test_helper'

class PaytooNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paytoo = Paytoo::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @paytoo.complete?
    assert_equal "", @paytoo.status
    assert_equal "", @paytoo.transaction_id
    assert_equal "", @paytoo.item_id
    assert_equal "", @paytoo.gross
    assert_equal "", @paytoo.currency
    assert_equal "", @paytoo.received_at
    assert @paytoo.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @paytoo.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @paytoo.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
