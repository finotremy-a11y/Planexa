require "test_helper"

class Company::WaitlistEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @service = create(:service_type, company: @company)
    @entry   = create(:waitlist_entry, company: @company, service_type: @service)
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_waitlist_entries_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_waitlist_entries_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get company_waitlist_entries_path
    assert_response :success
  end

  test "GET index n'affiche pas les entrées d'une autre entreprise" do
    other_entry = create(:waitlist_entry)
    get company_waitlist_entries_path
    assert_response :success
    assert_not_includes assigns(:entries) || [], other_entry
  end

  # — Show —
  test "GET show retourne 200" do
    get company_waitlist_entry_path(@entry)
    assert_response :success
  end

  test "GET show retourne 404 pour une entrée d'une autre entreprise" do
    other_entry = create(:waitlist_entry)
    get company_waitlist_entry_path(other_entry)
    assert_response :not_found
  end

  # — Destroy —
  test "DELETE destroy expire l'entrée" do
    delete company_waitlist_entry_path(@entry)
    assert_redirected_to company_waitlist_entries_path

    @entry.reload
    assert @entry.expired?
  end

  test "DELETE destroy redirige avec notice" do
    delete company_waitlist_entry_path(@entry)
    assert_redirected_to company_waitlist_entries_path
    assert_match "retirée", flash[:notice]
  end
end
