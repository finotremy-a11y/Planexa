require "test_helper"

class Company::StripeConnectsControllerTest < ActionDispatch::IntegrationTest
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
    get connect_company_stripe_connect_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get connect_company_stripe_connect_path
    assert_redirected_to root_path
  end

  # — Connect (compte Stripe inexistant) —
  test "GET connect crée un compte Stripe et redirige vers l'onboarding" do
    mock_account = stub(id: "acct_test_new", details_submitted: false)
    mock_link    = stub(url: "https://connect.stripe.com/setup/e/acct_test_new")

    Stripe::Account.stubs(:create).returns(mock_account)
    Stripe::AccountLink.stubs(:create).returns(mock_link)

    get connect_company_stripe_connect_path
    assert_response :redirect
    assert_match "stripe.com", response.location
    assert_equal "acct_test_new", @company.reload.stripe_account_id
  end

  test "GET connect avec compte Stripe existant et onboarding complet redirige vers dashboard" do
    @company.update!(stripe_account_id: "acct_existing_complete")
    mock_account = stub(details_submitted: true)
    Stripe::Account.stubs(:retrieve).returns(mock_account)

    get connect_company_stripe_connect_path
    assert_redirected_to company_root_path
  end

  test "GET connect avec compte Stripe existant non complet relance l'onboarding" do
    @company.update!(stripe_account_id: "acct_existing_incomplete")
    mock_account = stub(details_submitted: false)
    mock_link    = stub(url: "https://connect.stripe.com/setup/e/acct_existing_incomplete")

    Stripe::Account.stubs(:retrieve).returns(mock_account)
    Stripe::AccountLink.stubs(:create).returns(mock_link)

    get connect_company_stripe_connect_path
    assert_response :redirect
    assert_match "stripe.com", response.location
  end

  test "GET connect gère les erreurs Stripe avec une alerte" do
    Stripe::Account.stubs(:create).raises(Stripe::StripeError.new("Erreur test"))

    get connect_company_stripe_connect_path
    assert_redirected_to company_settings_path
    assert_match "Erreur Stripe", flash[:alert]
  end

  # — Return —
  test "GET return avec onboarding complet marque stripe_onboarding_complete" do
    @company.update!(stripe_account_id: "acct_return_complete")
    mock_account = stub(details_submitted: true)
    Stripe::Account.stubs(:retrieve).returns(mock_account)

    get return_company_stripe_connect_path
    assert @company.reload.stripe_onboarding_complete?
    assert_redirected_to company_settings_path
    assert_includes flash[:notice], "connecté"
  end

  test "GET return avec onboarding incomplet redirige avec alerte" do
    @company.update!(stripe_account_id: "acct_return_incomplete")
    mock_account = stub(details_submitted: false)
    Stripe::Account.stubs(:retrieve).returns(mock_account)

    get return_company_stripe_connect_path
    assert_redirected_to company_settings_path
    assert flash[:alert].present?
  end

  # — Refresh —
  test "GET refresh redirige vers connect" do
    get refresh_company_stripe_connect_path
    assert_redirected_to connect_company_stripe_connect_path
  end
end
