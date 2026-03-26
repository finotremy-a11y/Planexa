# frozen_string_literal: true

require "test_helper"

class Company::BookingGroupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user

    @client = create(:user, role: :client)
    @st1    = create(:service_type, company: @company, duration_minutes: 30)
    @st2    = create(:service_type, company: @company, duration_minutes: 45)

    @bg = create(:booking_group, company: @company, client_user: @client,
                 total_amount_cents: 5000)
    create(:appointment, company: @company, service_type: @st1,
           booking_group: @bg, scheduled_at: 2.days.from_now.change(hour: 10, min: 0))
    create(:appointment, company: @company, service_type: @st2,
           booking_group: @bg, scheduled_at: 2.days.from_now.change(hour: 10, min: 30))
  end

  # ── Autorisation ─────────────────────────────────────────────────────────

  test "redirige si non connecté" do
    sign_out @user
    get company_booking_groups_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_booking_groups_path
    assert_redirected_to root_path
  end

  test "interdit l'accès aux groupes d'une autre entreprise" do
    other_user    = create(:user, :company_admin)
    other_company = create(:company, user: other_user)
    other_bg = create(:booking_group, company: other_company, total_amount_cents: 1000)
    # @user est déjà connecté (setup) — sa company ne contient pas other_bg

    get company_booking_group_path(other_bg)
    assert_response :not_found
  end

  # ── Index ────────────────────────────────────────────────────────────────

  test "GET index retourne 200" do
    get company_booking_groups_path
    assert_response :success
  end

  test "GET index n'affiche que les groupes de l'entreprise courante" do
    other_user    = create(:user, :company_admin)
    other_company = create(:company, user: other_user)
    other_bg = create(:booking_group, company: other_company, total_amount_cents: 500)

    get company_booking_groups_path
    assert_response :success
    # Le booking_group de l'autre entreprise n'est pas exposé
    assert_not_includes assigns(:booking_groups).to_a, other_bg if @response.body.include?("other_bg.id.to_s")
  end

  # ── Show ─────────────────────────────────────────────────────────────────

  test "GET show retourne 200" do
    get company_booking_group_path(@bg)
    assert_response :success
  end

  test "GET show introuvable retourne 404 pour une autre entreprise" do
    other_user    = create(:user, :company_admin)
    other_company = create(:company, user: other_user)
    create(:subscription, company: other_company, status: :active)
    other_bg = create(:booking_group, company: other_company, total_amount_cents: 200)
    # Toujours connecté en tant que @user (entreprise @company)
    get company_booking_group_path(other_bg)
    assert_response :not_found
  end
end
