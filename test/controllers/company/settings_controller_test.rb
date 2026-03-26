require "test_helper"

class Company::SettingsControllerTest < ActionDispatch::IntegrationTest
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
    get company_settings_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_settings_path
    assert_redirected_to root_path
  end

  # — Show —
  test "GET show retourne 200" do
    get company_settings_path
    assert_response :success
    assert_select "h3", text: "🔔 Rappels clients (multi-canal)"
  end

  # — Update —
  test "PATCH update avec paramètres valides sauvegarde les réglages" do
    patch company_settings_path, params: {
      company_setting: {
        booking_mode:    "booking_public",
        payment_mode:    "payment_in_app",
        assignment_mode: "assignment_automatic",
        email_reminders_enabled: "1",
        sms_reminders_enabled: "0",
        push_reminders_enabled: "1",
        slot_interval_minutes: "20",
        buffer_between_appointments_minutes: "10",
        allow_controlled_overbooking: "1",
        overbooking_limit_per_slot: "1",
        emergency_daily_capacity: "4"
      }
    }
    setting = @company.reload.setting
    assert setting.booking_public?
    assert setting.payment_in_app?
    assert setting.assignment_automatic?
    assert setting.email_reminders_enabled?
    assert_not setting.sms_reminders_enabled?
    assert setting.push_reminders_enabled?
    assert_equal 20, setting.slot_interval_minutes
    assert_equal 10, setting.buffer_between_appointments_minutes
    assert setting.allow_controlled_overbooking?
    assert_equal 1, setting.overbooking_limit_per_slot
    assert_equal 4, setting.emergency_daily_capacity
    assert_redirected_to company_settings_path
  end

  test "PATCH update avec paramètres invalides affiche le formulaire" do
    patch company_settings_path, params: {
      company_setting: {
        booking_mode:    "",
        payment_mode:    "",
        assignment_mode: ""
      }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update met à jour le mode de réservation privé" do
    patch company_settings_path, params: {
      company_setting: {
        booking_mode:    "booking_private",
        payment_mode:    "payment_external",
        assignment_mode: "assignment_manual"
      }
    }
    setting = @company.reload.setting
    assert setting.booking_private?
    assert setting.payment_external?
    assert setting.assignment_manual?
  end
end
