require "test_helper"

class StripeSubscriptionServiceTest < ActiveSupport::TestCase
  setup do
    @company = create(:company, stripe_customer_id: nil)
    @service = StripeSubscriptionService.new(@company)

    @mock_customer = OpenStruct.new(id: "cus_test_123")
    @mock_session  = OpenStruct.new(id: "cs_test_abc", url: "https://checkout.stripe.com/test")
  end

  # — create_checkout_session —
  test "crée un customer Stripe et une Checkout Session si pas de stripe_customer_id" do
    Stripe::Customer.stubs(:create).returns(@mock_customer)
    Stripe::Checkout::Session.stubs(:create).returns(@mock_session)

    session = @service.create_checkout_session(
      success_url: "https://example.com/success",
      cancel_url:  "https://example.com/cancel"
    )

    assert_equal @mock_session, session
    assert_equal "cus_test_123", @company.reload.stripe_customer_id
  end

  test "réutilise le customer Stripe existant si stripe_customer_id présent" do
    @company.update!(stripe_customer_id: "cus_existing_456")
    service = StripeSubscriptionService.new(@company)

    Stripe::Customer.stubs(:retrieve).returns(@mock_customer)
    Stripe::Customer.expects(:create).never
    Stripe::Checkout::Session.stubs(:create).returns(@mock_session)

    session = service.create_checkout_session(
      success_url: "https://example.com/success",
      cancel_url:  "https://example.com/cancel"
    )
    assert_equal @mock_session, session
  end

  # — create_billing_portal_session —
  test "crée une session Billing Portal" do
    @company.update!(stripe_customer_id: "cus_portal_789")
    service = StripeSubscriptionService.new(@company)

    mock_portal = OpenStruct.new(url: "https://billing.stripe.com/test")
    Stripe::BillingPortal::Session.stubs(:create).returns(mock_portal)

    portal = service.create_billing_portal_session(return_url: "https://example.com/return")
    assert_equal mock_portal, portal
  end
end
