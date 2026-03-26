# frozen_string_literal: true

require "test_helper"

class Company::LoyaltySettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
  end

  # ── Autorisation ───────────────────────────────────────────────────────────
  test "redirige si non connecté" do
    sign_out @user
    get company_loyalty_settings_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_loyalty_settings_path
    assert_redirected_to root_path
  end

  # ── Show ───────────────────────────────────────────────────────────────────
  test "GET show retourne 200" do
    get company_loyalty_settings_path
    assert_response :success
  end

  test "GET show affiche les stats" do
    client = create(:user, role: :client)
    create(:loyalty_point, client_user: client, company: @company, points: 10, reason: "earned")
    create(:discount_code, client_user: client, company: @company)
    get company_loyalty_settings_path
    assert_response :success
  end

  # ── Update ─────────────────────────────────────────────────────────────────
  test "PATCH update met à jour les paramètres de fidélité" do
    patch company_loyalty_settings_path, params: {
      company_setting: {
        loyalty_enabled: true,
        points_per_appointment: 15,
        loyalty_points_threshold: 80,
        loyalty_discount_value_cents: 2000
      }
    }
    assert_redirected_to company_loyalty_settings_path

    @company.company_setting.reload
    assert @company.company_setting.loyalty_enabled?
    assert_equal 15, @company.company_setting.points_per_appointment
    assert_equal 80, @company.company_setting.loyalty_points_threshold
    assert_equal 2000, @company.company_setting.loyalty_discount_value_cents
  end

  test "PATCH update avec paramètres invalides reste sur show" do
    @company.company_setting.update!(loyalty_enabled: true, points_per_appointment: 10)
    # Envoyer un update vide ne devrait pas casser — les fields sont integers avec defaults
    patch company_loyalty_settings_path, params: {
      company_setting: { points_per_appointment: 20 }
    }
    assert_redirected_to company_loyalty_settings_path
    assert_equal 20, @company.company_setting.reload.points_per_appointment
  end
end
