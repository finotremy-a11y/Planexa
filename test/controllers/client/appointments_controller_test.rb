require "test_helper"

class Client::AppointmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client    = create(:user, role: :client)
    @company   = create(:company)
    @service   = create(:service_type, company: @company)
    sign_in @client
  end

  # — Index —
  test "GET index retourne 200 pour un client" do
    get client_appointments_path
    assert_response :success
  end

  test "GET index est refusé si non connecté" do
    sign_out @client
    get client_appointments_path
    assert_redirected_to new_user_session_path
  end

  test "GET index est refusé pour un company_admin" do
    company_user = create(:user, :company_admin)
    sign_in company_user
    get client_appointments_path
    assert_redirected_to root_path
  end

  # — Show —
  test "GET show retourne 200 pour le client propriétaire" do
    appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client)
    get client_appointment_path(appointment)
    assert_response :success
  end

  test "GET show retourne 404 pour un autre client" do
    other_client = create(:user, role: :client)
    appointment  = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  other_client)
    get client_appointment_path(appointment)
    assert_response :not_found
  end

  test "GET show affiche un CTA de rebooking pour un rendez-vous termine" do
    appointment = create(:appointment,
      company: @company,
      service_type: @service,
      client_user: @client,
      status: :completed)

    get client_appointment_path(appointment)

    assert_response :success
    assert_includes response.body, "Reprendre un rendez-vous similaire"
    assert_includes response.body, "company_id=#{@company.id}"
    assert_includes response.body, "service_type_id=#{@service.id}"
  end

  test "GET show n'affiche pas le CTA de rebooking si le rendez-vous n'est pas termine" do
    appointment = create(:appointment,
      company: @company,
      service_type: @service,
      client_user: @client,
      status: :confirmed)

    get client_appointment_path(appointment)

    assert_response :success
    assert_not_includes response.body, "Reprendre un rendez-vous similaire"
  end

  # — Cancel (destroy) —
  test "DELETE destroy annule un RDV pending" do
    appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      status:       :pending)
    delete client_appointment_path(appointment)
    assert appointment.reload.cancelled?
    assert_redirected_to client_appointments_path
  end

  test "DELETE destroy annule un RDV confirmed" do
    appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      status:       :confirmed)
    delete client_appointment_path(appointment)
    assert appointment.reload.cancelled?
  end

  test "DELETE destroy ne peut pas annuler un RDV completed" do
    appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      status:       :completed)
    delete client_appointment_path(appointment)
    assert appointment.reload.completed?
    assert_redirected_to client_appointments_path
  end

  test "DELETE destroy envoie un email d'annulation" do
    appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      status:       :pending)

    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test

    assert_enqueued_emails 1 do
      delete client_appointment_path(appointment)
    end
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  test "DELETE destroy autre client — 404" do
    other_client = create(:user, role: :client)
    appointment  = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  other_client,
      status:       :pending)
    delete client_appointment_path(appointment)
    assert_response :not_found
    assert_not appointment.reload.cancelled?
  end
end
