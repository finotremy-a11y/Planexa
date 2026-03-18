# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET index retourne 200 sans authentification" do
    get root_path
    assert_response :success
  end

  test "GET index retourne 200 avec des entreprises actives" do
    company = create(:company)
    company.setting.update!(booking_mode: :booking_public)
    create(:service_type, company: company)

    get root_path
    assert_response :success
  end

  test "GET index accessible en étant connecté comme client" do
    sign_in create(:user, role: :client)
    get root_path
    assert_response :success
  end

  test "GET index accessible en étant connecté comme company_admin" do
    sign_in create(:user, :company_admin)
    get root_path
    assert_response :success
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
