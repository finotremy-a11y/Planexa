# frozen_string_literal: true

require "test_helper"

class Company::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_root_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_root_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get company_root_path
    assert_response :success
  end

  test "GET index avec données retourne 200" do
    service  = create(:service_type, company: @company)
    employee = create(:employee, company: @company, active: true)
    create(:appointment, company: @company, service_type: service,
           scheduled_at: 2.days.from_now, status: :pending)
    create(:appointment, company: @company, service_type: service,
           scheduled_at: 2.days.from_now, status: :confirmed)

    get company_root_path
    assert_response :success
  end

  test "GET index entreprise suspendue redirige vers abonnement" do
    @company.update!(status: :suspended)
    get company_root_path
    assert_redirected_to company_subscription_path
  end
end
