# frozen_string_literal: true

require "test_helper"

class WidgetControllerTest < ActionDispatch::IntegrationTest
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
      @employee.schedules.create!(company: @company, day_of_week: day,
                                  start_time: "08:00", end_time: "20:00",
                                  available: true, schedule_type: "recurring")
    end

    @token        = @company.widget_token
    @scheduled_at = 2.days.from_now.change(hour: 10, min: 0, sec: 0)
  end

  # ── GET booking ─────────────────────────────────────────────────────────

  test "GET booking retourne 200 pour un token valide" do
    get widget_booking_path(company_token: @token)
    assert_response :success
    assert_select "form"
  end

  test "GET booking retourne 404 pour un token inconnu" do
    get widget_booking_path(company_token: "token-inconnu")
    assert_response :not_found
  end

  test "GET booking retourne 404 si l'entreprise est suspendue" do
    @company.update_column(:status, 1)  # suspended
    get widget_booking_path(company_token: @token)
    assert_response :not_found
  end

  test "GET booking ne présente pas la navigation PlanifyPro" do
    get widget_booking_path(company_token: @token)
    assert_response :success
    # Le layout widget n'inclut pas de nav globale
    assert_select "nav.navbar", count: 0
  end

  test "GET booking inclut l'entête X-Frame-Options supprimé (iframe autorisé)" do
    get widget_booking_path(company_token: @token)
    assert_nil response.headers["X-Frame-Options"]
  end

  # ── POST create ─────────────────────────────────────────────────────────

  test "POST create réussit et redirige vers la confirmation" do
    assert_difference "BookingGroup.count", 1 do
      assert_difference "Appointment.count", 2 do
        post widget_booking_create_path(company_token: @token), params: {
          booking_group: {
            service_type_ids: [ @st1.id, @st2.id ],
            scheduled_at:     @scheduled_at.strftime("%Y-%m-%dT%H:%M")
          }
        }
      end
    end
    assert_redirected_to widget_booking_confirmation_path(
      company_token: @token,
      booking_group_id: BookingGroup.last.id
    )
  end

  test "POST create avec service invalide réaffiche le formulaire" do
    post widget_booking_create_path(company_token: @token), params: {
      booking_group: {
        service_type_ids: [ @st1.id ],  # une seule prestation → erreur
        scheduled_at:     @scheduled_at.strftime("%Y-%m-%dT%H:%M")
      }
    }
    assert_response :unprocessable_entity
  end

  test "POST create avec token invalide retourne 404" do
    post widget_booking_create_path(company_token: "faux-token"), params: {
      booking_group: {
        service_type_ids: [ @st1.id, @st2.id ],
        scheduled_at:     @scheduled_at.strftime("%Y-%m-%dT%H:%M")
      }
    }
    assert_response :not_found
  end

  # ── GET confirmation ─────────────────────────────────────────────────────

  test "GET confirmation affiche le récapitulatif" do
    bg = create(:booking_group, company: @company, total_amount_cents: 5000)
    create(:appointment, company: @company, service_type: @st1,
           booking_group: bg, scheduled_at: @scheduled_at)
    create(:appointment, company: @company, service_type: @st2,
           booking_group: bg, scheduled_at: @scheduled_at + 30.minutes)

    get widget_booking_confirmation_path(company_token: @token, booking_group_id: bg.id)
    assert_response :success
  end

  test "GET confirmation avec booking_group_id invalide redirige vers le formulaire" do
    get widget_booking_confirmation_path(company_token: @token, booking_group_id: 0)
    assert_redirected_to widget_booking_path(company_token: @token)
  end
end
