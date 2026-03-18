# frozen_string_literal: true

require "test_helper"

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = create(:company)
    @company.setting.update!(booking_mode: :booking_public)
    create(:service_type, company: @company)
  end

  test "GET show retourne 200 sans authentification" do
    get company_public_path(@company)
    assert_response :success
  end

  test "GET show retourne 200 en étant connecté" do
    sign_in create(:user, role: :client)
    get company_public_path(@company)
    assert_response :success
  end

  test "GET show avec une entreprise inactive retourne 404" do
    @company.update!(status: :suspended)
    get company_public_path(@company)
    assert_response :not_found
  end

  test "GET show avec un id inexistant retourne 404" do
    get company_public_path(id: 0)
    assert_response :not_found
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
