require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # — Authorization —
  test "redirige vers login si non connecté" do
    sign_out @admin
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "redirige vers root si company_admin" do
    company_user = create(:user, :company_admin)
    create(:company, user: company_user)
    sign_in company_user
    get admin_root_path
    assert_redirected_to root_path
  end

  test "redirige vers root si client" do
    sign_in create(:user, role: :client)
    get admin_root_path
    assert_redirected_to root_path
  end

  # — Index (dashboard) —
  test "GET index retourne 200" do
    get admin_root_path
    assert_response :success
  end

  test "GET index charge les métriques globales" do
    create(:company)
    get admin_root_path
    assert_response :success
  end

  # — Metrics (JSON) —
  test "GET metrics retourne du JSON" do
    get admin_metrics_path
    assert_response :success
    assert_includes response.content_type, "application/json"
  end

  test "GET metrics retourne les clés attendues" do
    get admin_metrics_path
    data = JSON.parse(response.body)
    assert data.key?("companies_by_day")
    assert data.key?("revenue_by_month")
  end

  test "GET metrics est refusé pour un non-admin" do
    sign_in create(:user, role: :client)
    get admin_metrics_path
    assert_redirected_to root_path
  end

  # — Export CSV —
  test "GET export_csv retourne un fichier CSV" do
    get admin_export_csv_path
    assert_response :success
    assert_equal "text/csv", response.content_type
  end

  test "GET export_csv contient les en-têtes attendus" do
    get admin_export_csv_path
    assert_match "Nom", response.body
    assert_match "SIRET", response.body
    assert_match "Email", response.body
  end

  test "GET export_csv contient les données entreprises" do
    company = create(:company, name: "Entreprise Test CSV")
    get admin_export_csv_path
    assert_match "Entreprise Test CSV", response.body
  end

  test "GET export_csv est refusé pour un non-admin" do
    sign_in create(:user, role: :client)
    get admin_export_csv_path
    assert_redirected_to root_path
  end
end
