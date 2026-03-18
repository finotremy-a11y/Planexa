require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @company = create(:company, name: "Plomberie Lyon", city: "Lyon", status: :active)
    @company.company_setting.update!(booking_mode: :booking_public)
    create(:service_type, company: @company, name: "Plomberie")
  end

  test "GET index retourne 200" do
    get search_path
    assert_response :success
  end

  test "filtre par nom retourne la bonne entreprise" do
    get search_path, params: { name: "Plomberie" }
    assert_response :success
    assert_select "body", /Plomberie Lyon/
  end

  test "filtre par activité retourne la bonne entreprise" do
    get search_path, params: { activity: "Plomberie" }
    assert_response :success
    assert_select "body", /Plomberie Lyon/
  end

  test "entreprise privée n'apparaît pas dans les résultats" do
    private_company = create(:company, name: "Privée SA")
    private_company.company_setting.update!(booking_mode: :booking_private)
    get search_path, params: { name: "Privée" }
    assert_response :success
    assert_select "body", { text: /Privée SA/, count: 0 }
  end

  test "filtre urgent ne lève pas d'erreur" do
    get search_path, params: { urgent: "1" }
    assert_response :success
  end
end
