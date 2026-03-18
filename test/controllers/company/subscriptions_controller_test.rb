require "test_helper"

class Company::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    sign_in @user
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_subscription_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_subscription_path
    assert_redirected_to root_path
  end

  # — Show —
  test "GET show retourne 200" do
    create(:subscription, company: @company)
    get company_subscription_path
    assert_response :success
  end

  test "GET show retourne 200 sans abonnement" do
    get company_subscription_path
    assert_response :success
  end

  # — New —
  test "GET new retourne 200 si pas d'abonnement actif" do
    get new_company_subscription_path
    assert_response :success
  end

  test "GET new redirige si abonnement déjà actif" do
    create(:subscription, company: @company, status: :active)
    get new_company_subscription_path
    assert_redirected_to company_subscription_path
  end

  # — Create (Stripe mocké) —
  test "POST create redirige vers Stripe Checkout" do
    mock_session = stub(url: "https://checkout.stripe.com/pay/cs_test_123")
    StripeSubscriptionService.any_instance.stubs(:create_checkout_session).returns(mock_session)

    post company_subscription_path
    assert_response :redirect
    assert_match "stripe.com", response.location
  end

  test "POST create gère les erreurs Stripe" do
    StripeSubscriptionService.any_instance.stubs(:create_checkout_session)
      .raises(Stripe::StripeError.new("Erreur Stripe"))

    post company_subscription_path
    assert_redirected_to new_company_subscription_path
  end

  # — Destroy —
  test "DELETE destroy annule l'abonnement" do
    subscription = create(:subscription,
      company:                @company,
      status:                 :active,
      stripe_subscription_id: "sub_test_cancel")

    Stripe::Subscription.stubs(:cancel)

    delete company_subscription_path
    assert subscription.reload.canceled?
    assert @company.reload.suspended?
    assert_redirected_to company_subscription_path
  end

  test "DELETE destroy sans abonnement redirige avec alerte" do
    delete company_subscription_path
    assert_redirected_to company_subscription_path
  end

  # — Portal —
  test "POST portal redirige vers Stripe Billing Portal" do
    create(:subscription, company: @company)
    mock_portal = stub(url: "https://billing.stripe.com/p/session_test")
    StripeSubscriptionService.any_instance.stubs(:create_billing_portal_session).returns(mock_portal)

    post portal_company_subscription_path
    assert_response :redirect
    assert_match "stripe.com", response.location
  end
end
