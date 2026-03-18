require "test_helper"

class Company::ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_profile_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_profile_path
    assert_redirected_to root_path
  end

  # — Show —
  test "GET show retourne 200" do
    get company_profile_path
    assert_response :success
  end

  # — Edit —
  test "GET edit retourne 200" do
    get edit_company_profile_path
    assert_response :success
  end

  # — Update —
  test "PATCH update avec données valides met à jour le profil" do
    patch company_profile_path, params: {
      company: {
        name:        "Nouveau Nom SARL",
        city:        "Lyon",
        address:     "12 rue de la Paix",
        zip_code:    "69001",
        phone:       "0478000000",
        description: "Description mise à jour",
        website:     "https://example.com"
      }
    }
    assert_equal "Nouveau Nom SARL", @company.reload.name
    assert_equal "Lyon", @company.reload.city
    assert_redirected_to company_profile_path
  end

  test "PATCH update avec données invalides affiche le formulaire" do
    patch company_profile_path, params: {
      company: { name: "" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update ne peut pas modifier le profil d'une autre entreprise" do
    other_user    = create(:user, :company_admin)
    other_company = create(:company, user: other_user, name: "Autre Entreprise")
    # Connecté en tant que @user, tente de modifier other_company
    patch company_profile_path, params: {
      company: { name: "Hacked" }
    }
    # Le controller modifie @company (scopé à current_user), pas other_company
    assert_not_equal "Hacked", other_company.reload.name
  end
end
