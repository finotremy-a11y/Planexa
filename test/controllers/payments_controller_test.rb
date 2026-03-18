# frozen_string_literal: true

require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client  = create(:user, role: :client)
    @company = create(:company)
    @company.setting.update!(
      payment_mode:    :payment_in_app,
      assignment_mode: :assignment_manual,
      booking_mode:    :booking_public
    )
    @service     = create(:service_type, company: @company)
    @appointment = create(:appointment,
                          company:      @company,
                          service_type: @service,
                          client_user:  @client,
                          status:       :pending)
    sign_in @client
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @client
    get new_appointment_payment_path(appointment_id: @appointment.id)
    assert_redirected_to new_user_session_path
  end

  test "redirige si le RDV appartient à un autre utilisateur" do
    other_client = create(:user, role: :client)
    sign_in other_client
    get new_appointment_payment_path(appointment_id: @appointment.id)
    assert_redirected_to root_path
  end

  # — GET new —
  test "GET new redirige vers la confirmation si paiement non requis" do
    @company.setting.update!(payment_mode: :payment_external)
    get new_appointment_payment_path(appointment_id: @appointment.id)
    assert_redirected_to confirmation_appointments_path(appointment_id: @appointment.id)
  end

  test "GET new redirige vers la confirmation si déjà payé" do
    create(:payment, :succeeded,
           appointment: @appointment,
           client_user: @client,
           company:     @company)
    get new_appointment_payment_path(appointment_id: @appointment.id)
    assert_redirected_to confirmation_appointments_path(appointment_id: @appointment.id)
  end

  test "GET new retourne 200 et initialise le PaymentIntent" do
    mock_intent  = stub(client_secret: "pi_test_secret_stripe")
    mock_service = stub(create_payment_intent: mock_intent)
    StripePaymentService.stubs(:new).returns(mock_service)

    get new_appointment_payment_path(appointment_id: @appointment.id)
    assert_response :success
  end

  test "GET new gère une erreur Stripe et redirige vers la racine" do
    StripePaymentService.stubs(:new).raises(StandardError, "Erreur Stripe simulée")
    get new_appointment_payment_path(appointment_id: @appointment.id)
    assert_redirected_to root_path
  end

  # — POST create —
  test "POST create avec paiement réussi retourne JSON success" do
    create(:payment, :succeeded,
           appointment:              @appointment,
           client_user:              @client,
           company:                  @company,
           stripe_payment_intent_id: "pi_test_success")

    post appointment_payment_path(appointment_id: @appointment.id),
         params: { payment_intent_id: "pi_test_success" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "success", json["status"]
    assert_includes json["redirect_url"], "confirmation"
  end

  test "POST create avec paiement en attente retourne JSON pending" do
    create(:payment,
           appointment:              @appointment,
           client_user:              @client,
           company:                  @company,
           stripe_payment_intent_id: "pi_test_pending")

    post appointment_payment_path(appointment_id: @appointment.id),
         params: { payment_intent_id: "pi_test_pending" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "pending", json["status"]
  end

  test "POST create avec payment_intent_id introuvable retourne JSON pending" do
    post appointment_payment_path(appointment_id: @appointment.id),
         params: { payment_intent_id: "pi_does_not_exist" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "pending", json["status"]
  end
end
