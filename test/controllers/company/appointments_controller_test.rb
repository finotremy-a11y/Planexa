require "test_helper"

class Company::AppointmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    @service     = create(:service_type, company: @company)
    sign_in @user
  end

  test "GET index retourne 200" do
    get company_appointments_path
    assert_response :success
  end

  test "GET new retourne 200" do
    get new_company_appointment_path
    assert_response :success
  end

  test "POST create crée un rendez-vous" do
    assert_difference("Appointment.count", 1) do
      post company_appointments_path, params: {
        appointment: {
          service_type_id:  @service.id,
          scheduled_at:     2.days.from_now.change(hour: 10, min: 0),
          duration_minutes: 60
        }
      }
    end
  end

  test "PATCH confirm passe le RDV en confirmed" do
    appointment = create(:appointment, company: @company, service_type: @service, status: :pending)
    patch confirm_company_appointment_path(appointment)
    assert appointment.reload.confirmed?
  end

  test "PATCH cancel passe le RDV en cancelled" do
    appointment = create(:appointment, company: @company, service_type: @service, status: :pending)
    patch cancel_company_appointment_path(appointment)
    assert appointment.reload.cancelled?
  end

  test "isolation - RDV d'une autre entreprise retourne 404" do
    other_company = create(:company)
    other_service = create(:service_type, company: other_company)
    other_appt    = create(:appointment, company: other_company, service_type: other_service)
    get company_appointment_path(other_appt)
    assert_response :not_found
  end
end
