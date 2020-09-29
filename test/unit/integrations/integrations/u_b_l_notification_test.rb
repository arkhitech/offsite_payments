require 'test_helper'

class UBLNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @u_b_l = UBL::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @u_b_l.complete?
    assert_equal "", @u_b_l.status
    assert_equal "", @u_b_l.transaction_id
    assert_equal "", @u_b_l.item_id
    assert_equal "", @u_b_l.gross
    assert_equal "", @u_b_l.currency
    assert_equal "", @u_b_l.received_at
    assert @u_b_l.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @u_b_l.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @u_b_l.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
