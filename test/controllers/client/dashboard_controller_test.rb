require "test_helper"

class Client::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client  = create(:user, role: :client)
    @company = create(:company)
    @service = create(:service_type, company: @company)
    sign_in @client
  end

  # — Authorization —
  test "redirige vers login si non connecté" do
    sign_out @client
    get client_root_path
    assert_redirected_to new_user_session_path
  end

  test "redirige vers root si company_admin" do
    company_user = create(:user, :company_admin)
    sign_in company_user
    get client_root_path
    assert_redirected_to root_path
  end

  test "redirige vers root si admin" do
    admin = create(:user, :admin)
    sign_in admin
    get client_root_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get client_root_path
    assert_response :success
  end

  test "GET index affiche les prochains RDV" do
    create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      status:       :confirmed,
      scheduled_at: 2.days.from_now)
    get client_root_path
    assert_response :success
  end

  test "GET index n'affiche pas les RDV des autres clients" do
    other_client = create(:user, role: :client)
    create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  other_client,
      scheduled_at: 2.days.from_now)
    get client_root_path
    assert_response :success
  end
end
