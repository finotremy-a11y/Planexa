require "test_helper"

class Stripe::WebhooksControllerTest < ActionDispatch::IntegrationTest
  # Helpers pour construire des payloads Stripe mock
  def stripe_event_payload(type, data_object)
    JSON.generate({
      id:   "evt_test_#{SecureRandom.hex(8)}",
      type: type,
      data: { object: data_object }
    })
  end

  def post_webhook(payload, signature: "valid_sig")
    post "/stripe/webhooks",
      params:  payload,
      headers: {
        "HTTP_STRIPE_SIGNATURE" => signature,
        "CONTENT_TYPE"          => "application/json"
      }
  end

  def with_valid_webhook(type, data_object)
    payload = stripe_event_payload(type, data_object)
    mock_event = Stripe::Event.construct_from(JSON.parse(payload))

    Stripe::Webhook.stubs(:construct_event).returns(mock_event)
    begin
      post_webhook(payload)
    ensure
      Stripe::Webhook.unstub(:construct_event)
    end
  end

  # — Signature invalide —
  test "retourne 422 si signature Stripe invalide" do
    Stripe::Webhook.stubs(:construct_event).raises(Stripe::SignatureVerificationError.new("bad sig", "header"))
    begin
      post_webhook("{}", signature: "invalid")
    ensure
      Stripe::Webhook.unstub(:construct_event)
    end
    assert_response 422
  end

  # — payment_intent.succeeded —
  test "payment_intent.succeeded met le paiement en succeeded et confirme le RDV" do
    company     = create(:company)
    service     = create(:service_type, company: company)
    client      = create(:user, role: :client)
    appointment = create(:appointment, company: company, service_type: service, client_user: client)
    payment     = create(:payment,
      appointment:              appointment,
      client_user:              client,
      company:                  company,
      stripe_payment_intent_id: "pi_succeeded_test",
      status:                   :pending)

    with_valid_webhook("payment_intent.succeeded", {
      "id"     => "pi_succeeded_test",
      "object" => "payment_intent"
    })

    assert_response :success
    assert payment.reload.succeeded?
    assert appointment.reload.confirmed?
  end

  test "payment_intent.succeeded est idempotent (déjà succeeded)" do
    company     = create(:company)
    service     = create(:service_type, company: company)
    client      = create(:user, role: :client)
    appointment = create(:appointment, company: company, service_type: service, client_user: client, status: :confirmed)
    payment     = create(:payment,
      appointment:              appointment,
      client_user:              client,
      company:                  company,
      stripe_payment_intent_id: "pi_already_done",
      status:                   :succeeded,
      paid_at:                  1.hour.ago)

    original_paid_at = payment.paid_at
    with_valid_webhook("payment_intent.succeeded", {
      "id" => "pi_already_done"
    })

    assert_response :success
    assert_in_delta original_paid_at.to_i, payment.reload.paid_at.to_i, 5
  end

  # — invoice.payment_succeeded —
  test "invoice.payment_succeeded réactive un abonnement past_due" do
    company      = create(:company)
    subscription = create(:subscription,
      company:                @company || company,
      stripe_subscription_id: "sub_invoice_test",
      status:                 :past_due)

    with_valid_webhook("invoice.payment_succeeded", {
      "id"           => "in_test_123",
      "subscription" => "sub_invoice_test",
      "lines"        => { "data" => [ { "period" => { "end" => 30.days.from_now.to_i } } ] }
    })

    assert_response :success
    assert subscription.reload.active?
  end

  # — invoice.payment_failed —
  test "invoice.payment_failed passe l'abonnement en past_due" do
    company      = create(:company)
    subscription = create(:subscription,
      company:                company,
      stripe_subscription_id: "sub_failed_test",
      status:                 :active)

    with_valid_webhook("invoice.payment_failed", {
      "id"           => "in_failed_123",
      "subscription" => "sub_failed_test"
    })

    assert_response :success
    assert subscription.reload.past_due?
  end

  # — customer.subscription.deleted —
  test "customer.subscription.deleted annule l'abonnement et suspend la company" do
    company      = create(:company)
    subscription = create(:subscription,
      company:                company,
      stripe_subscription_id: "sub_deleted_test",
      status:                 :active)

    with_valid_webhook("customer.subscription.deleted", {
      "id"       => "sub_deleted_test",
      "customer" => "cus_test"
    })

    assert_response :success
    assert subscription.reload.canceled?
    assert company.reload.suspended?
  end

  # — Événement inconnu —
  test "événement non géré retourne 200 sans erreur" do
    with_valid_webhook("unknown.event.type", { "id" => "unknown" })
    assert_response :success
  end

  # — Réponse JSON —
  test "retourne JSON { received: true } en cas de succès" do
    with_valid_webhook("unknown.event.type", {})
    assert_equal({ "received" => true }, JSON.parse(response.body))
  end
end
