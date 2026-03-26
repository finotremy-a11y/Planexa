require "test_helper"

class Company::CompanyClosuresControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @closure = create(:company_closure, company: @company)
  end

  test "GET index retourne 200" do
    get company_company_closures_path
    assert_response :success
    assert_includes response.body, "Fermetures ponctuelles"
  end

  test "GET new retourne 200" do
    get new_company_company_closure_path
    assert_response :success
  end

  test "POST create cree une fermeture" do
    assert_difference("CompanyClosure.count", 1) do
      post company_company_closures_path, params: {
        company_closure: {
          starts_at: 3.days.from_now.change(hour: 8),
          ends_at: 3.days.from_now.change(hour: 12),
          reason: "Formation",
          note: "Matinee reservee"
        }
      }
    end

    assert_redirected_to company_company_closures_path
  end

  test "POST create invalide retourne 422" do
    assert_no_difference("CompanyClosure.count") do
      post company_company_closures_path, params: {
        company_closure: {
          starts_at: Time.current,
          ends_at: 1.hour.ago,
          reason: "Erreur"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "DELETE destroy supprime la fermeture" do
    assert_difference("CompanyClosure.count", -1) do
      delete company_company_closure_path(@closure)
    end

    assert_redirected_to company_company_closures_path
  end

  test "isolation - fermeture d'une autre entreprise retourne 404" do
    other_closure = create(:company_closure)

    delete company_company_closure_path(other_closure)

    assert_response :not_found
  end
end
