require 'test_helper'

class PaytooTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Paytoo::Notification, Paytoo.notification('name=cody')
  end
end
