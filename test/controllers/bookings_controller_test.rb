# frozen_string_literal: true

require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @company = create(:company)
    @company.setting.update!(booking_mode: :booking_public)

    @st1 = create(:service_type, company: @company, duration_minutes: 30, price_cents: 2000, active: true)
    @st2 = create(:service_type, company: @company, duration_minutes: 45, price_cents: 3000, active: true)

    @employee = create(:employee, company: @company, active: true)
    @employee.employee_skills.create!(service_type: @st1)
    @employee.employee_skills.create!(service_type: @st2)
    (0..6).each do |day|
      @employee.schedules.create!(company: @company, day_of_week: day, start_time: "08:00", end_time: "20:00",
                                   available: true, schedule_type: :recurring)
    end

    @client       = create(:user, role: :client)
    @scheduled_at = 2.days.from_now.change(hour: 10, min: 0, sec: 0)
  end

  # ── GET new ────────────────────────────────────────────────────────────────

  test "GET new retourne 200 pour une entreprise publique" do
    get new_booking_path(company_id: @company.id)
    assert_response :success
    assert_select "form"
  end

  test "GET new affiche les prestations actives" do
    get new_booking_path(company_id: @company.id)
    assert_response :success
    assert_select "input[type=checkbox]", count: ServiceType.where(company: @company, active: true).count
  end

  test "GET new redirige si réservation privée" do
    @company.setting.update!(booking_mode: :booking_private)
    get new_booking_path(company_id: @company.id)
    assert_redirected_to company_public_path(@company)
  end

  test "GET new accessible sans authentification" do
    get new_booking_path(company_id: @company.id)
    assert_response :success
  end

  test "GET new redirige si entreprise introuvable" do
    get new_booking_path(company_id: 0)
    assert_redirected_to search_path
  end

  # ── POST create ─────────────────────────────────────────────────────────

  test "POST create réussit et crée BookingGroup + appointments" do
    assert_difference "BookingGroup.count", 1 do
      assert_difference "Appointment.count", 2 do
        post bookings_path(company_id: @company.id), params: {
          booking_group: {
            service_type_ids: [ @st1.id, @st2.id ],
            scheduled_at:     @scheduled_at.strftime("%Y-%m-%dT%H:%M"),
            client_notes:     "Test notes"
          }
        }
      end
    end
    assert_redirected_to confirmation_bookings_path(booking_group_id: BookingGroup.last.id)
  end

  test "POST create avec utilisateur connecté associe le client" do
    sign_in @client
    post bookings_path(company_id: @company.id), params: {
      booking_group: {
        service_type_ids: [ @st1.id, @st2.id ],
        scheduled_at:     @scheduled_at.strftime("%Y-%m-%dT%H:%M")
      }
    }
    assert_equal @client, BookingGroup.last.client_user
  end

  test "POST create avec service invalide réaffiche le formulaire" do
    post bookings_path(company_id: @company.id), params: {
      booking_group: {
        service_type_ids: [ @st1.id ],  # une seule prestation → erreur
        scheduled_at:     @scheduled_at.strftime("%Y-%m-%dT%H:%M")
      }
    }
    assert_response :unprocessable_entity
  end

  test "POST create entreprise introuvable redirige vers la recherche" do
    post bookings_path(company_id: 0), params: {
      booking_group: {
        service_type_ids: [ @st1.id, @st2.id ],
        scheduled_at:     @scheduled_at.strftime("%Y-%m-%dT%H:%M")
      }
    }
    assert_redirected_to search_path
  end

  # ── GET confirmation ─────────────────────────────────────────────────────

  test "GET confirmation affiche le résumé de réservation" do
    bg = create(:booking_group, company: @company, client_user: @client,
                total_amount_cents: 5000)
    create(:appointment, company: @company, service_type: @st1,
           booking_group: bg, scheduled_at: @scheduled_at)
    create(:appointment, company: @company, service_type: @st2,
           booking_group: bg, scheduled_at: @scheduled_at + 30.minutes)

    get confirmation_bookings_path(booking_group_id: bg.id)
    assert_response :success
  end
end
