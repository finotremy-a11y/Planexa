# frozen_string_literal: true

require "test_helper"

class Company::OnboardingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, :company_admin)
    sign_in @user
  end

  test "GET show retourne 200 pour un company_admin sans entreprise" do
    get company_onboarding_path

    assert_response :success
    assert_select "h1", text: "Créez votre profil entreprise"
  end

  test "PATCH update crée l'entreprise et redirige vers le dashboard" do
    patch company_onboarding_path, params: {
      company: {
        name: "Planexa Test",
        siret: "12345678901234",
        address: "1 rue de Test",
        city: "Paris",
        zip_code: "75001",
        phone: "0102030405"
      }
    }

    assert_redirected_to company_root_path
    assert_equal "Planexa Test", @user.reload.company.name
  end

  test "PATCH update reaffiche le formulaire si les donnees sont invalides" do
    patch company_onboarding_path, params: {
      company: {
        name: "",
        siret: "123",
        address: "",
        city: "",
        zip_code: ""
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert.alert-error"
  end
end