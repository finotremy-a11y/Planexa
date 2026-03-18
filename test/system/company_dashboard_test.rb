require "application_system_test_case"

class CompanyDashboardTest < ApplicationSystemTestCase
  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
  end

  test "connexion et affichage dashboard" do
    visit new_user_session_path
    fill_in "Adresse email", with: @user.email
    fill_in "Mot de passe", with: "password123"
    click_on "Se connecter"
    assert_current_path company_root_path
    assert_text "Tableau de bord"
    assert_text @company.name
  end

  test "navigation vers les employés" do
    sign_in @user
    visit company_root_path
    click_on "Employés"
    assert_current_path company_employees_path
  end

  test "navigation vers les prestations" do
    sign_in @user
    visit company_root_path
    click_on "Prestations"
    assert_current_path company_service_types_path
  end

  test "navigation vers les réglages" do
    sign_in @user
    visit company_root_path
    click_on "Réglages"
    assert_current_path company_settings_path
  end
end
