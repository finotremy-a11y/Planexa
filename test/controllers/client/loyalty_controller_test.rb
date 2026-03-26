# frozen_string_literal: true

require "test_helper"

class Client::LoyaltyControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client  = create(:user, role: :client)
    @company = create(:company)
    @company.company_setting.update!(loyalty_enabled: true, points_per_appointment: 10,
                                     loyalty_points_threshold: 50)
    sign_in @client
  end

  # ── Autorisation ───────────────────────────────────────────────────────────
  test "redirige si non connecté" do
    sign_out @client
    get client_loyalty_index_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si company_admin" do
    sign_in create(:user, :company_admin)
    get client_loyalty_index_path
    assert_redirected_to root_path
  end

  # ── Index ──────────────────────────────────────────────────────────────────
  test "GET index retourne 200" do
    create(:loyalty_point, client_user: @client, company: @company, points: 10, reason: "earned")
    get client_loyalty_index_path
    assert_response :success
  end

  test "GET index retourne 200 sans points" do
    get client_loyalty_index_path
    assert_response :success
  end

  # ── Show ───────────────────────────────────────────────────────────────────
  test "GET show retourne 200" do
    create(:loyalty_point, client_user: @client, company: @company, points: 10, reason: "earned")
    get client_loyalty_path(@company)
    assert_response :success
  end

  test "GET show affiche les codes de réduction" do
    create(:loyalty_point, client_user: @client, company: @company, points: 10, reason: "earned")
    create(:discount_code, client_user: @client, company: @company)
    get client_loyalty_path(@company)
    assert_response :success
  end
end
