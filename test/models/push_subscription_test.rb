# test/models/push_subscription_test.rb
require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  setup do
    @user    = create(:user)
    @company = create(:company)
    @subscription_params = {
      user: @user,
      company: @company,
      endpoint: "https://example.com/push/123456",
      auth: "test_auth_key",
      p256dh: "test_p256dh_key"
    }
  end

  test "creates valid push subscription" do
    subscription = PushSubscription.new(@subscription_params)
    assert subscription.save
    assert_equal @user, subscription.user
    assert_equal @company, subscription.company
  end

  test "requires endpoint" do
    subscription = PushSubscription.new(@subscription_params.except(:endpoint))
    assert_not subscription.save
    assert_includes subscription.errors[:endpoint], "can't be blank"
  end

  test "requires auth" do
    subscription = PushSubscription.new(@subscription_params.except(:auth))
    assert_not subscription.save
    assert_includes subscription.errors[:auth], "can't be blank"
  end

  test "requires p256dh" do
    subscription = PushSubscription.new(@subscription_params.except(:p256dh))
    assert_not subscription.save
    assert_includes subscription.errors[:p256dh], "can't be blank"
  end

  test "enforces unique endpoint per user and company" do
    # Create first subscription
    subscription1 = PushSubscription.create!(@subscription_params)

    # Try to create duplicate
    subscription2 = PushSubscription.new(@subscription_params)
    assert_not subscription2.save
  end

  test "allows same endpoint for different users" do
    endpoint = "https://example.com/push/same"
    sub1 = PushSubscription.create!(
      user: @user,
      company: @company,
      endpoint: endpoint,
      auth: "auth1",
      p256dh: "p256dh1"
    )

    other_user = create(:user)
    sub2 = PushSubscription.create!(
      user: other_user,
      company: @company,
      endpoint: endpoint,
      auth: "auth2",
      p256dh: "p256dh2"
    )

    assert sub1.persisted?
    assert sub2.persisted?
  end

  test "for_company scope filters by company" do
    subscription = PushSubscription.create!(@subscription_params)
    other_company = create(:company)

    assert_includes PushSubscription.for_company(@company), subscription
    assert_not_includes PushSubscription.for_company(other_company), subscription
  end

  test "for_user scope filters by user" do
    subscription = PushSubscription.create!(@subscription_params)
    other_user = create(:user)

    assert_includes PushSubscription.for_user(@user), subscription
    assert_not_includes PushSubscription.for_user(other_user), subscription
  end

  test "recent scope orders by created_at desc" do
    sub1 = PushSubscription.create!(@subscription_params)
    sub2_params = @subscription_params.merge(endpoint: "https://example.com/push/456")
    sub2 = PushSubscription.create!(sub2_params)

    recent = PushSubscription.recent
    assert_equal sub2.id, recent.first.id
    assert_equal sub1.id, recent.last.id
  end
end
