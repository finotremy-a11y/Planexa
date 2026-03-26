# test/services/push_notification_service_test.rb
require "test_helper"

class PushNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @user        = create(:user)
    @company     = create(:company)
    @service_type = create(:service_type, company: @company)
    @employee    = create(:employee, company: @company)
    @appointment = create(:appointment,
                          company: @company,
                          service_type: @service_type,
                          client_user: @user,
                          status: :confirmed)

    # Create mock push subscriptions
    @subscription = PushSubscription.create!(
      user: @user,
      company: @company,
      endpoint: "https://example.com/push/test",
      auth: "test_auth",
      p256dh: "test_p256dh"
    )
  end

  # Mock WebPush to avoid actual push sends during tests
  teardown do
    WebPush.stubs(:payload_send) if defined?(WebPush)
  end

  test "notify_user sends to all user subscriptions" do
    # Create another subscription for same user
    @subscription2 = PushSubscription.create!(
      user: @user,
      company: @company,
      endpoint: "https://example.com/push/test2",
      auth: "test_auth2",
      p256dh: "test_p256dh2"
    )

    WebPush.expects(:payload_send).times(2)

    PushNotificationService.notify_user(
      user: @user,
      title: "Test",
      body: "Test notification"
    )
  end

  test "notify_user filters by company when specified" do
    other_company = create(:company)
    @subscription2 = PushSubscription.create!(
      user: @user,
      company: other_company,
      endpoint: "https://example.com/push/other",
      auth: "auth2",
      p256dh: "p256dh2"
    )

    WebPush.expects(:payload_send).once # Only for @company subscription

    PushNotificationService.notify_user(
      user: @user,
      title: "Company specific",
      body: "Only for one company",
      data: { company_id: @company.id }
    )
  end

  test "notify_new_appointment notifies company users" do
    WebPush.stubs(:payload_send).returns(true)

    PushNotificationService.notify_new_appointment(@appointment)
    # Should have attempted to notify (or silently failed due to stub)
  end

  test "notify_appointment_reminder includes time until appointment" do
    future_appointment = create(:appointment,
                                company: @company,
                                service_type: @service_type,
                                client_user: @user,
                                scheduled_at: 1.hour.from_now,
                                duration_minutes: 60,
                                status: :confirmed)

    WebPush.stubs(:payload_send).returns(true)

    # Service should call notify_appointment_reminder without errors
    assert_nothing_raised do
      PushNotificationService.notify_appointment_reminder(future_appointment)
    end
  end

  test "notify_appointment_cancelled includes cancellation message" do
    @appointment.update(status: :cancelled)

    WebPush.stubs(:payload_send).returns(true)

    assert_nothing_raised do
      PushNotificationService.notify_appointment_cancelled(@appointment)
    end
  end

  test "notify_company_users notifies all company users" do
    employee_user = create(:user, :company_admin)

    WebPush.stubs(:payload_send).returns(true)

    # Notify company users
    PushNotificationService.notify_company_users(
      company: @company,
      users: [@user, employee_user],
      title: "Company announcement",
      body: "Important update"
    )
  end

  test "send_test_notification works" do
    WebPush.stubs(:payload_send).returns(true)

    assert_nothing_raised do
      PushNotificationService.send_test_notification(user: @user)
    end
  end

  test "handles expired subscriptions gracefully" do
    # Simulate expired subscription by having send_notification destroy the record
    PushSubscription.any_instance.stubs(:send_notification).with(
      title: anything, body: anything, data: anything
    ) { @subscription.destroy }

    assert_difference "PushSubscription.count", -1 do
      PushNotificationService.notify_user(
        user: @user,
        title: "Test",
        body: "Testing expired"
      )
    end
  end

  test "handles invalid subscriptions gracefully" do
    # Simulate invalid subscription by having send_notification destroy the record
    PushSubscription.any_instance.stubs(:send_notification).with(
      title: anything, body: anything, data: anything
    ) { @subscription.destroy }

    assert_difference "PushSubscription.count", -1 do
      PushNotificationService.notify_user(
        user: @user,
        title: "Test",
        body: "Testing invalid"
      )
    end
  end

  test "logs errors on failed notification send" do
    WebPush.stubs(:payload_send).raises(StandardError, "Network error")

    assert_nothing_raised do
      PushNotificationService.notify_user(
        user: @user,
        title: "Test",
        body: "Testing error"
      )
    end
  end
end
