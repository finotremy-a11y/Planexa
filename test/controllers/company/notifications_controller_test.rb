# frozen_string_literal: true

require "test_helper"

class Company::NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user

    @notification1 = create(:notification, company: @company, kind: :new_booking)
    @notification2 = create(:notification, company: @company, kind: :cancellation,
                             read_at: 1.hour.ago)
  end

  # ── Autorisation ─────────────────────────────────────────────────────────

  test "redirige si non connecté" do
    sign_out @user
    get company_notifications_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_notifications_path
    assert_redirected_to root_path
  end

  # ── Index ────────────────────────────────────────────────────────────────

  test "GET index retourne 200 et marque les non lues comme lues" do
    assert_equal 1, @company.notifications.unread.count

    get company_notifications_path
    assert_response :success
    # Après la visite, toutes sont marquées lues
    assert_equal 0, @company.notifications.unread.reload.count
  end

  test "GET index affiche les notifications" do
    get company_notifications_path
    assert_response :success
    assert_match "Nouvelle réservation", response.body
  end

  # ── Mark all read ────────────────────────────────────────────────────────

  test "PATCH mark_all_read marque toutes comme lues" do
    create(:notification, company: @company, kind: :urgent)  # deuxième non lue

    patch mark_all_read_company_notifications_path
    assert_redirected_to company_notifications_path
    assert_equal 0, @company.notifications.unread.reload.count
  end
end
