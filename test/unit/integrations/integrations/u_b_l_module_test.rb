require 'test_helper'

class UBLTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of UBL::Notification, UBL.notification('name=cody')
  end
end
