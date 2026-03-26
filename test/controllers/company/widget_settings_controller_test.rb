# frozen_string_literal: true

require "test_helper"

class Company::WidgetSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
  end

  # ── Autorisation ─────────────────────────────────────────────────────────

  test "redirige si non connecté" do
    sign_out @user
    get company_widget_settings_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client tente d'accéder" do
    sign_in create(:user, role: :client)
    get company_widget_settings_path
    assert_redirected_to root_path
  end

  # ── Show ─────────────────────────────────────────────────────────────────

  test "GET show retourne 200 et affiche le token" do
    get company_widget_settings_path
    assert_response :success
    assert_match @company.widget_token, response.body
  end

  test "GET show contient le code d'intégration iFrame" do
    get company_widget_settings_path
    assert_response :success
    assert_match "iframe", response.body
    assert_match @company.widget_token, response.body
  end

  test "GET show affiche un QR code imprimable vers la fiche publique" do
    get company_widget_settings_path

    assert_response :success
    assert_match "QR code de réservation", response.body
    assert_match company_public_url(@company), response.body
    assert_match "<svg", response.body
  end

  # ── Régénération du token ────────────────────────────────────────────────

  test "POST regenerate_token change le token et redirige" do
    old_token = @company.widget_token
    post regenerate_token_company_widget_settings_path
    assert_redirected_to company_widget_settings_path
    assert_not_equal old_token, @company.reload.widget_token
  end

  test "POST regenerate_token affiche un notice de succès" do
    post regenerate_token_company_widget_settings_path
    assert_redirected_to company_widget_settings_path
    follow_redirect!
    assert_match "Token régénéré", response.body
  end
end
