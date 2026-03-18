require "application_system_test_case"

# Tests système pour l'espace admin
class AdminDashboardTest < ApplicationSystemTestCase
  setup do
    @admin   = create(:user, :admin)
    @company = create(:company, status: :active)
    create(:subscription, company: @company, status: :active)
    sign_in @admin
  end

  test "admin peut accéder au dashboard" do
    visit admin_root_path
    assert_response_ok
  end

  test "admin peut voir la liste des entreprises" do
    visit admin_companies_path
    assert_text @company.name
  end

  test "admin peut voir le détail d'une entreprise" do
    visit admin_company_path(@company)
    assert_text @company.name
    assert_text @company.siret
  end

  test "admin peut voir la liste des utilisateurs" do
    visit admin_users_path
    assert_text @admin.email
  end

  test "admin peut voir la liste des abonnements" do
    visit admin_subscriptions_path
    assert_response_ok
  end

  test "accès admin refusé pour un client" do
    client = create(:user, role: :client)
    sign_in client
    visit admin_root_path
    assert_current_path root_path
  end

  private

  def assert_response_ok
    assert_no_text "Accès non autorisé"
    assert_no_text "500"
  end
end
