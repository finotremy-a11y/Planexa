require "test_helper"

class Client::ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client = create(:user, role: :client)
    sign_in @client
  end

  test "GET show retourne 200 pour un client" do
    get client_profile_path
    assert_response :success
  end

  test "GET show redirige vers login si non connecté" do
    sign_out @client
    get client_profile_path
    assert_redirected_to new_user_session_path
  end

  test "GET show redirige vers root pour un company_admin" do
    company_user = create(:user, :company_admin)
    sign_in company_user

    get client_profile_path

    assert_redirected_to root_path
  end

  test "PATCH update met à jour les infos du profil" do
    patch client_profile_path, params: {
      user: {
        first_name: "Jean",
        last_name: "Dupont",
        phone: "0601020304",
        sms_opt_out: "1",
        locale: "fr"
      }
    }

    assert_redirected_to client_profile_path
    @client.reload
    assert_equal "Jean", @client.first_name
    assert_equal "Dupont", @client.last_name
    assert_equal "0601020304", @client.phone
    assert @client.sms_opt_out?
    assert_equal "fr", @client.locale
  end
end
