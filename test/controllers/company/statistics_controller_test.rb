# frozen_string_literal: true

require "test_helper"

class Company::StatisticsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
  end

  # ── Autorisation ──────────────────────────────────────────────────────────

  test "redirige si non connecté" do
    sign_out @user
    get company_statistics_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_statistics_path
    assert_redirected_to root_path
  end

  # ── Index ─────────────────────────────────────────────────────────────────

  test "GET index retourne 200 sans données" do
    get company_statistics_path
    assert_response :success
  end

  test "GET index avec période par défaut 30 jours" do
    get company_statistics_path
    assert_response :success
    assert_equal 30, assigns(:period)
  end

  test "GET index avec période 7 jours" do
    get company_statistics_path(period: 7)
    assert_response :success
    assert_equal 7, assigns(:period)
  end

  test "GET index avec période 90 jours" do
    get company_statistics_path(period: 90)
    assert_response :success
    assert_equal 90, assigns(:period)
  end

  test "GET index ramène les périodes inconnues à 30" do
    get company_statistics_path(period: 999)
    assert_response :success
    assert_equal 30, assigns(:period)
  end

  test "GET index avec données de RDV" do
    service  = create(:service_type, company: @company)
    employee = create(:employee, company: @company, active: true)
    client   = create(:user, role: :client)
    (0..6).each do |day|
      create(:schedule,
        company: @company,
        employee: employee,
        day_of_week: day,
        start_time: "00:00",
        end_time: "23:59",
        schedule_type: "recurring")
    end

    create(:appointment, :completed, company: @company, service_type: service,
           client_user: client, employee: employee,
           scheduled_at: 5.days.ago)
    create(:appointment, :cancelled, company: @company, service_type: service,
           scheduled_at: 3.days.ago)
    create(:appointment, company: @company, service_type: service,
           status: :no_show, scheduled_at: 2.days.ago)

    get company_statistics_path(period: 30)
    assert_response :success
    assert_equal 3,    assigns(:total_appointments)
    assert_equal 1,    assigns(:completed_count)
    assert_equal 1,    assigns(:cancelled_count)
    assert_equal 1,    assigns(:no_show_count)
  end

  test "GET index calcule le no_show_rate" do
    service = create(:service_type, company: @company)
    4.times { create(:appointment, :completed, company: @company, service_type: service, scheduled_at: 5.days.ago) }
    1.times { create(:appointment, company: @company, service_type: service, status: :no_show, scheduled_at: 5.days.ago) }

    get company_statistics_path(period: 30)
    assert_equal 20.0, assigns(:no_show_rate)
  end

  test "GET index calcule le CA à partir des paiements réussis" do
    service = create(:service_type, company: @company)
    appt    = create(:appointment, :completed, company: @company, service_type: service, scheduled_at: 5.days.ago)
    create(:payment, :succeeded, appointment: appt, company: @company,
           client_user: create(:user), amount_cents: 7500, paid_at: 5.days.ago)

    get company_statistics_path(period: 30)
    assert_equal 7500, assigns(:total_revenue_cents)
    assert_equal 7500, assigns(:avg_basket_cents)
  end

  test "GET index n'inclut pas les RDV hors période" do
    service = create(:service_type, company: @company)
    create(:appointment, :completed, company: @company, service_type: service,
           scheduled_at: 200.days.ago)

    get company_statistics_path(period: 30)
    assert_equal 0, assigns(:total_appointments)
  end

  # ── Export CSV ────────────────────────────────────────────────────────────

  test "GET export_csv retourne un fichier CSV" do
    get company_export_statistics_csv_path(period: 30)
    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.content_type
    assert_includes response.headers["Content-Disposition"], ".csv"
  end

  test "GET export_csv contient les entêtes CSV" do
    get company_export_statistics_csv_path(period: 30)
    assert_includes response.body, "Date"
    assert_includes response.body, "Prestation"
    assert_includes response.body, "Statut"
  end

  test "GET export_csv contient les données RDV" do
    service = create(:service_type, company: @company, name: "Coupe homme")
    create(:appointment, :completed, company: @company, service_type: service,
           scheduled_at: 5.days.ago)

    get company_export_statistics_csv_path(period: 30)
    assert_includes response.body, "Coupe homme"
  end
end
