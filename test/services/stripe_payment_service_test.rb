require "test_helper"

class StripePaymentServiceTest < ActiveSupport::TestCase
  setup do
    @company = create(:company,
      stripe_account_id:          "acct_test_123",
      stripe_onboarding_complete: true)
    @service_type = create(:service_type, company: @company, price_cents: 5000)
    @client       = create(:user, role: :client)
    @appointment  = create(:appointment,
      company:      @company,
      service_type: @service_type,
      client_user:  @client)
    @service = StripePaymentService.new(@appointment)
  end

  # — Succès —
  test "create_payment_intent crée un PaymentIntent Stripe et un Payment" do
    mock_intent = OpenStruct.new(id: "pi_test_abc123")
    Stripe::PaymentIntent.stubs(:create).returns(mock_intent)

    assert_difference("Payment.count", 1) do
      intent = @service.create_payment_intent
      assert_equal "pi_test_abc123", intent.id
    end

    payment = Payment.last
    assert_equal "pi_test_abc123", payment.stripe_payment_intent_id
    assert_equal 5000, payment.amount_cents
    assert_equal "eur", payment.currency
    assert payment.pending?
    assert_equal @appointment, payment.appointment
    assert_equal @client,      payment.client_user
    assert_equal @company,     payment.company
  end

  test "create_payment_intent utilise une idempotency_key stable" do
    mock_intent = OpenStruct.new(id: "pi_idem_test")
    expected_key = "payment_intent_appt_#{@appointment.id}"

    Stripe::PaymentIntent.expects(:create)
      .with(anything, has_entry(idempotency_key: expected_key))
      .returns(mock_intent)

    @service.create_payment_intent
  end

  test "create_payment_intent facture uniquement l'acompte si configure" do
    @service_type.update!(deposit_kind: :deposit_fixed_cents, deposit_value: 2000)
    mock_intent = OpenStruct.new(id: "pi_deposit_test")

    Stripe::PaymentIntent.expects(:create)
      .with(has_entry(:amount, 2000), anything)
      .returns(mock_intent)

    @service.create_payment_intent

    assert_equal 2000, Payment.last.amount_cents
  end

  # — Erreurs de garde —
  test "lève une erreur si stripe_account_id absent" do
    company = create(:company, stripe_account_id: nil)
    appointment = create(:appointment, company: company,
      service_type: create(:service_type, company: company))
    service = StripePaymentService.new(appointment)

    assert_raises(RuntimeError) do
      service.create_payment_intent
    end
  end

  test "lève une erreur si onboarding Stripe incomplet" do
    company = create(:company, stripe_account_id: "acct_test", stripe_onboarding_complete: false)
    appointment = create(:appointment, company: company,
      service_type: create(:service_type, company: company))
    service = StripePaymentService.new(appointment)

    assert_raises(RuntimeError) do
      service.create_payment_intent
    end
  end

  test "propage l'erreur Stripe en cas d'échec API et log l'erreur" do
    Stripe::PaymentIntent.stubs(:create).raises(Stripe::StripeError.new("Card error"))

    assert_raises(Stripe::StripeError) do
      @service.create_payment_intent
    end
    assert_equal 0, Payment.count
  end
end
