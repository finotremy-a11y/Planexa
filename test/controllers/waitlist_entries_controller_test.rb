require "test_helper"

class WaitlistEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @company = create(:company)
    @company.setting.update!(booking_mode: :booking_public)
    @service = create(:service_type, company: @company)
  end

  # — New —
  test "GET new retourne 200 sans connexion" do
    get new_waitlist_entry_path(company_id: @company.id)
    assert_response :success
  end

  test "GET new retourne 200 pour client connecté" do
    sign_in create(:user, role: :client)
    get new_waitlist_entry_path(company_id: @company.id)
    assert_response :success
  end

  # — Create —
  test "POST create crée une entrée pour invité" do
    assert_difference("WaitlistEntry.count", 1) do
      post waitlist_entries_path, params: {
        waitlist_entry: {
          company_id:      @company.id,
          service_type_id: @service.id,
          client_name:     "Jean Dupont",
          client_email:    "jean@test.com",
          preferred_date:  3.days.from_now.to_date.to_s
        }
      }
    end
    assert_redirected_to waitlist_submitted_path
  end

  test "POST create crée une entrée pour client connecté" do
    client = create(:user, role: :client)
    sign_in client

    assert_difference("WaitlistEntry.count", 1) do
      post waitlist_entries_path, params: {
        waitlist_entry: {
          company_id:      @company.id,
          service_type_id: @service.id
        }
      }
    end

    entry = WaitlistEntry.last
    assert_equal client.id, entry.client_user_id
    assert_redirected_to waitlist_submitted_path
  end

  test "POST create avec données invalides affiche le formulaire" do
    post waitlist_entries_path, params: {
      waitlist_entry: {
        company_id:      @company.id,
        service_type_id: @service.id,
        client_name:     "",
        client_email:    ""
      }
    }
    assert_response :unprocessable_entity
  end

  # — Confirm —
  test "GET confirm avec token valide redirige vers la prise de RDV" do
    entry = create(:waitlist_entry, :notified, company: @company, service_type: @service,
                   notified_at: 1.hour.ago)

    get waitlist_confirm_path(token: entry.token)
    assert_redirected_to new_appointment_path(company_id: @company.id, service_type_id: @service.id)

    entry.reload
    assert entry.expired?
  end

  test "GET confirm avec token expiré redirige avec alerte" do
    entry = create(:waitlist_entry, :expired, company: @company, service_type: @service)

    get waitlist_confirm_path(token: entry.token)
    assert_redirected_to root_path
    assert_match "expiré", flash[:alert]
  end

  test "GET confirm avec notification expirée (24h+) expire l'entrée" do
    entry = create(:waitlist_entry, company: @company, service_type: @service,
                   notified_at: 25.hours.ago)

    get waitlist_confirm_path(token: entry.token)
    assert_redirected_to root_path
    assert_match "24h", flash[:alert]

    entry.reload
    assert entry.expired?
  end

  test "GET confirm avec entrée non notifiée redirige" do
    entry = create(:waitlist_entry, company: @company, service_type: @service)

    get waitlist_confirm_path(token: entry.token)
    assert_redirected_to root_path
  end

  test "GET confirm avec token invalide redirige" do
    get waitlist_confirm_path(token: "invalid-token")
    assert_redirected_to root_path
  end

  # — Submitted —
  test "GET submitted retourne 200" do
    get waitlist_submitted_path
    assert_response :success
  end
end
