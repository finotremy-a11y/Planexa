require "test_helper"

class Company::InactiveClientsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create(:user, :company_admin)
    @company = create(:company, user: @owner)
    create(:subscription, company: @company, status: :active)
    sign_in @owner

    @service = create(:service_type, company: @company)
  end

  test "GET index retourne 200 pour un company admin" do
    get company_inactive_clients_path
    assert_response :success
  end

  test "GET index liste les clients inactifs et propose une action de relance" do
    inactive_client = create(:user, role: :client, first_name: "Lea", last_name: "Martin")
    active_client = create(:user, role: :client, first_name: "Hugo", last_name: "Bernard")

    create(:appointment, company: @company, service_type: @service,
                         client_user: inactive_client, scheduled_at: 90.days.ago)
    create(:appointment, company: @company, service_type: @service,
                         client_user: active_client, scheduled_at: 5.days.ago)

    get company_inactive_clients_path, params: { days: 60 }

    assert_response :success
    assert_includes response.body, "Lea Martin"
    assert_not_includes response.body, "Hugo Bernard"
    assert_includes response.body, "mailto:"
  end

  test "GET index redirige si non connecte" do
    sign_out @owner

    get company_inactive_clients_path

    assert_redirected_to new_user_session_path
  end
end
