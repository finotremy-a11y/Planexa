require "test_helper"

class Admin::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin        = create(:user, :admin)
    @company      = create(:company)
    @subscription = create(:subscription, company: @company,
      stripe_subscription_id: "sub_test_abc",
      status: :active)
    sign_in @admin
  end

  # — Accès —
  test "index redirige si non admin" do
    sign_out @admin
    get admin_subscriptions_path
    assert_redirected_to new_user_session_path
  end

  # — Index —
  test "GET index retourne 200" do
    get admin_subscriptions_path
    assert_response :success
  end

  # — Show —
  test "GET show retourne 200" do
    get admin_subscription_path(@subscription)
    assert_response :success
  end

  # — Cancel —
  test "PATCH cancel annule l'abonnement Stripe et suspend la company" do
    Stripe::Subscription.stubs(:cancel).returns(true)
    begin
      patch cancel_admin_subscription_path(@subscription)
    ensure
      Stripe::Subscription.unstub(:cancel)
    end
    assert @subscription.reload.canceled?
    assert @company.reload.suspended?
    assert_redirected_to admin_subscription_path(@subscription)
  end

  test "PATCH cancel gère l'erreur Stripe gracieusement" do
    Stripe::Subscription.stubs(:cancel).raises(Stripe::StripeError.new("API error"))
    begin
      patch cancel_admin_subscription_path(@subscription)
    ensure
      Stripe::Subscription.unstub(:cancel)
    end
    assert_not @subscription.reload.canceled?
    assert_redirected_to admin_subscription_path(@subscription)
  end

  test "GET show retourne 404 pour un abonnement inexistant" do
    get admin_subscription_path(id: 0)
    assert_response :not_found
  end
end
