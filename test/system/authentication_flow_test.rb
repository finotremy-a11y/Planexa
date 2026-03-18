require "application_system_test_case"

# Tests système pour le flow d'authentification complet
class AuthenticationFlowTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "test.auth@example.com", password: "password123", role: :client)
  end

  test "utilisateur peut se connecter avec email/password valides" do
    visit new_user_session_path
    fill_in "Email", with: "test.auth@example.com"
    fill_in "Mot de passe", with: "password123"
    click_button "Se connecter"
    assert_current_path root_path
  end

  test "connexion échouée avec mauvais mot de passe" do
    visit new_user_session_path
    fill_in "Email", with: "test.auth@example.com"
    fill_in "Mot de passe", with: "wrong_password"
    click_button "Se connecter"
    assert_text "Email ou mot de passe incorrect"
  end

  test "utilisateur peut s'inscrire et confirmer son compte" do
    visit new_user_registration_path
    fill_in "Prénom",          with: "Marie"
    fill_in "Nom",             with: "Dupont"
    fill_in "Email",           with: "new.user.#{SecureRandom.hex(4)}@example.com"
    fill_in "Mot de passe",    with: "SecurePass123!"
    fill_in "Confirmer",       with: "SecurePass123!"
    click_button "S'inscrire"
    # Confirmation par email requise
    assert_text "Un email de confirmation"
  end

  test "utilisateur peut se déconnecter" do
    sign_in @user
    visit root_path
    click_link "Déconnexion" rescue click_button "Déconnexion"
    assert_current_path root_path
  end
end
