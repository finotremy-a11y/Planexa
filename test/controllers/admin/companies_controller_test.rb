require "test_helper"

class Admin::CompaniesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin   = create(:user, :admin)
    @company = create(:company)
    create(:subscription, company: @company, status: :active)
    sign_in @admin
  end

  # — Accès refusé aux non-admins —
  test "index redirige si non connecté" do
    sign_out @admin
    get admin_companies_path
    assert_redirected_to new_user_session_path
  end

  test "index redirige si company_admin" do
    company_user = create(:user, :company_admin)
    sign_in company_user
    get admin_companies_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get admin_companies_path
    assert_response :success
  end

  test "GET index avec filtre categorie statut ne plante pas" do
    create(:company, status: :suspended)

    get admin_companies_path, params: { q: { status_eq: "active" } }

    assert_response :success
  end

  # — Show —
  test "GET show retourne 200" do
    get admin_company_path(@company)
    assert_response :success
  end

  # — Suspend —
  test "PATCH suspend suspend l'entreprise" do
    @company.active!
    patch suspend_admin_company_path(@company)
    assert @company.reload.suspended?
    assert_redirected_to admin_company_path(@company)
  end

  test "PATCH suspend met à jour le statut de l'abonnement" do
    @company.active!
    patch suspend_admin_company_path(@company)
    assert_equal "suspended", @company.subscription.reload.status
  end

  # — Reactivate —
  test "PATCH reactivate réactive l'entreprise" do
    @company.suspended!
    patch reactivate_admin_company_path(@company)
    assert @company.reload.active?
    assert_redirected_to admin_company_path(@company)
  end

  # — Destroy —
  test "DELETE destroy supprime l'entreprise" do
    assert_difference("Company.count", -1) do
      delete admin_company_path(@company)
    end
    assert_redirected_to admin_companies_path
  end

  # — 404 —
  test "GET show retourne 404 pour une company inexistante" do
    get admin_company_path(id: 0)
    assert_response :not_found
  end
end
