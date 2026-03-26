# frozen_string_literal: true

require "test_helper"

class Company::DashboardControllerTest < ActionDispatch::IntegrationTest
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
    get company_root_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_root_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get company_root_path
    assert_response :success
  end

  test "GET index avec données retourne 200" do
    service  = create(:service_type, company: @company)
    employee = create(:employee, company: @company, active: true)
    create(:appointment, company: @company, service_type: service,
           scheduled_at: 2.days.from_now, status: :pending)
    create(:appointment, company: @company, service_type: service,
           scheduled_at: 2.days.from_now, status: :confirmed)

    get company_root_path
    assert_response :success
  end

  test "dashboard affiche les reservations generees ce mois" do
    service = create(:service_type, company: @company)

    create_list(:appointment, 2, company: @company, service_type: service,
                                 booking_source: :online, created_at: 2.days.ago)
    create(:appointment, company: @company, service_type: service,
                         booking_source: :manual, created_at: 2.days.ago)
    create(:appointment, company: @company, service_type: service,
                         booking_source: :online, created_at: 40.days.ago)

    get company_root_path

    assert_response :success
    assert_includes response.body, I18n.t("dashboard.bookings_generated_this_month")
    assert_includes response.body, "<div class=\"stat-value\">2</div>"
  end

  test "dashboard affiche le CA estime genere avec methode de calcul" do
    paid_service = create(:service_type, company: @company, price_cents: 1500)
    second_service = create(:service_type, company: @company, price_cents: 2500)

    create(:appointment, company: @company, service_type: paid_service,
                         booking_source: :online, status: :pending, created_at: 3.days.ago)
    create(:appointment, company: @company, service_type: second_service,
                         booking_source: :online, status: :confirmed, created_at: 2.days.ago)
    create(:appointment, company: @company, service_type: second_service,
                         booking_source: :online, status: :cancelled, created_at: 1.day.ago)
    create(:appointment, company: @company, service_type: second_service,
                         booking_source: :manual, status: :confirmed, created_at: 1.day.ago)

    get company_root_path

    assert_response :success
    assert_includes response.body, I18n.t("dashboard.estimated_turnover_this_month")
    assert_includes response.body, I18n.t("dashboard.estimated_turnover_formula")
    assert_includes response.body, "40,00 €"
  end

  test "dashboard affiche les no-show evites avec methode explicable" do
    standard_service = create(:service_type, company: @company, price_cents: 2000)
    deposit_service = create(:service_type, company: @company,
                                       price_cents: 5000,
                                       deposit_kind: :deposit_fixed_cents,
                                       deposit_value: 1500)

    reconfirmed = create(:appointment, company: @company, service_type: standard_service,
                                       status: :completed, scheduled_at: 5.days.ago,
                                       reconfirmed_at: 6.days.ago)

    deposit_paid = create(:appointment, company: @company, service_type: deposit_service,
                                        status: :completed, scheduled_at: 4.days.ago)
    create(:payment, :succeeded, appointment: deposit_paid, company: @company,
                                client_user: create(:user, role: :client))

    reminded = create(:appointment, company: @company, service_type: standard_service,
                                    status: :confirmed, scheduled_at: 3.days.ago)
    ReminderDelivery.create!(company: @company, appointment: reminded, channel: :email, status: :sent)

    create(:appointment, company: @company, service_type: standard_service,
                         status: :completed, scheduled_at: 2.days.ago)
    cancelled_with_signal = create(:appointment, company: @company, service_type: standard_service,
                                                 status: :cancelled, scheduled_at: 1.day.ago,
                                                 reconfirmed_at: 2.days.ago)
    ReminderDelivery.create!(company: @company, appointment: cancelled_with_signal, channel: :email, status: :sent)

    get company_root_path

    assert_response :success
    assert_includes response.body, I18n.t("dashboard.no_show_avoided_this_month")
    assert_includes response.body, I18n.t("dashboard.no_show_avoided_formula")
    assert_includes response.body, "<div class=\"stat-value\">3</div>"
  end

  test "dashboard affiche la checklist onboarding et les bloqueurs" do
    get company_root_path

    assert_response :success
    assert_select "h3", text: "Mise en ligne"
    assert_select "span", text: "Configuration incomplete"
    assert_select "a[href='#{company_profile_path}']", text: "Profil entreprise"
    assert_select "a[href='#{company_schedules_path}']", text: "Horaires"
    assert_select "a[href='#{company_service_types_path}']", text: "Prestations"
    assert_select "a[href='#{company_settings_path}']", text: "Page publique active"
    assert_select "a[href='#{company_settings_path}']", text: "Paiement en ligne"
  end

  test "dashboard affiche entreprise prete quand checklist complete" do
    @company.update!(phone: "0600000000")
    create(:service_type, company: @company, active: true)
    employee = create(:employee, company: @company, active: true)
    create(:schedule, company: @company, employee: employee, available: true)

    get company_root_path

    assert_response :success
    assert_includes response.body, "Pret a recevoir des reservations"
  end

  test "paiement en ligne est bloque tant que stripe n'est pas connecte" do
    @company.setting.update!(payment_mode: :payment_in_app)

    get company_root_path

    assert_response :success
    assert_select "span", text: "Configuration incomplete"
    assert_select "span", text: "Requis"
  end

  test "GET index entreprise suspendue redirige vers abonnement" do
    @company.update!(status: :suspended)
    get company_root_path
    assert_redirected_to company_subscription_path
  end
end
