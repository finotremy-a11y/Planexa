require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  # — Accès —
  test "index redirige si non connecté" do
    sign_out @admin
    get admin_users_path
    assert_redirected_to new_user_session_path
  end

  test "index redirige si company_admin" do
    company_user = create(:user, :company_admin)
    sign_in company_user
    get admin_users_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get admin_users_path
    assert_response :success
  end

  test "GET index avec filtre categorie role ne plante pas" do
    create(:user, :client)
    create(:user, :company_admin)

    get admin_users_path, params: { q: { role_eq: "client" } }

    assert_response :success
  end

  # — Show —
  test "GET show retourne 200" do
    user = create(:user)
    get admin_user_path(user)
    assert_response :success
  end

  # — Destroy —
  test "DELETE destroy supprime un autre utilisateur" do
    user = create(:user)
    assert_difference("User.count", -1) do
      delete admin_user_path(user)
    end
    assert_redirected_to admin_users_path
  end

  test "DELETE destroy ne peut pas supprimer son propre compte" do
    assert_no_difference("User.count") do
      delete admin_user_path(@admin)
    end
    assert_redirected_to admin_users_path
  end

  test "GET show retourne 404 pour un utilisateur inexistant" do
    get admin_user_path(id: 0)
    assert_response :not_found
  end
end
