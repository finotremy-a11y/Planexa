# frozen_string_literal: true

require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @company = create(:company)
    @service = create(:service_type, company: @company, duration_minutes: 60)
    # Mode manuel + paiement externe pour simplifier les tests de base
    @company.setting.update!(
      booking_mode:    :booking_public,
      payment_mode:    :payment_external,
      assignment_mode: :assignment_manual
    )
  end

  # — GET new —
  test "GET new entreprise publique retourne 200" do
    get new_appointment_path, params: { company_id: @company.id }
    assert_response :success
  end

  test "GET new entreprise privée redirige vers la fiche publique" do
    @company.setting.update!(booking_mode: :booking_private)
    get new_appointment_path, params: { company_id: @company.id }
    assert_redirected_to company_public_path(@company)
  end

  test "GET new entreprise introuvable redirige vers la recherche" do
    get new_appointment_path, params: { company_id: 0 }
    assert_redirected_to search_path
  end

  test "GET new accessible sans authentification" do
    get new_appointment_path, params: { company_id: @company.id }
    assert_response :success
  end

  test "GET new pre-remplit le service et la date depuis les params" do
    prefilled_time = 2.days.from_now.change(hour: 10, min: 30, sec: 0)

    get new_appointment_path, params: {
      company_id: @company.id,
      service_type_id: @service.id,
      scheduled_at: prefilled_time.strftime("%Y-%m-%dT%H:%M")
    }

    assert_response :success
    assert_select "input[name='appointment[service_type_id]'][value='#{@service.id}']", minimum: 1
    assert_includes response.body, prefilled_time.strftime("%Y-%m-%dT%H:%M")
  end

  test "GET new affiche les informations critiques en permanence" do
    get new_appointment_path, params: { company_id: @company.id }

    assert_response :success
    assert_includes response.body, "Informations essentielles"
    assert_includes response.body, "Annulation"
    assert_includes response.body, @company.city
  end

  test "GET new avec une seule prestation n'affiche pas de liste radio" do
    company = create(:company)
    service = create(:service_type, company: company)
    company.setting.update!(
      booking_mode: :booking_public,
      payment_mode: :payment_external,
      assignment_mode: :assignment_manual
    )

    get new_appointment_path, params: { company_id: company.id }

    assert_response :success
    assert_select "input[type=hidden][name='appointment[service_type_id]'][value='#{service.id}']"
    assert_select "input[type=radio][name='appointment[service_type_id]']", count: 0
  end

  # — POST create —
  test "POST create valide sans paiement redirige vers la confirmation" do
    assert_difference "Appointment.count", 1 do
      post appointments_path, params: {
        company_id: @company.id,
        appointment: {
          service_type_id: @service.id,
          scheduled_at:    2.days.from_now.change(hour: 10, min: 0, sec: 0)
        }
      }
    end
    assert_redirected_to confirmation_appointments_path(appointment_id: Appointment.last.id)
  end

  test "POST create avec paiement in-app redirige vers le paiement" do
    client = create(:user, role: :client)
    sign_in client
    @company.setting.update!(payment_mode: :payment_in_app)

    post appointments_path, params: {
      company_id: @company.id,
      appointment: {
        service_type_id: @service.id,
        scheduled_at:    2.days.from_now.change(hour: 10, min: 0, sec: 0)
      }
    }

    appt = Appointment.last
    assert_redirected_to new_appointment_payment_path(appointment_id: appt.id)
  end

  test "POST create entreprise introuvable redirige vers la recherche" do
    post appointments_path, params: {
      company_id: 0,
      appointment: {
        service_type_id: @service.id,
        scheduled_at:    2.days.from_now.change(hour: 10, min: 0, sec: 0)
      }
    }
    assert_redirected_to search_path
  end

  test "POST create avec paramètres invalides affiche le formulaire" do
    post appointments_path, params: {
      company_id: @company.id,
      appointment: { service_type_id: nil, scheduled_at: nil }
    }
    assert_response :unprocessable_entity
  end

  # — GET show —
  test "GET show retourne 200 sans authentification" do
    appt = create(:appointment, company: @company, service_type: @service)
    get appointment_path(appt)
    assert_response :success
  end

  # — GET confirmation —
  test "GET confirmation retourne 200 sans authentification" do
    appt = create(:appointment, company: @company, service_type: @service)
    get confirmation_appointments_path, params: { appointment_id: appt.id }
    assert_response :success
  end

  test "GET confirmation affiche les actions de reassurance et suite" do
    appt = create(:appointment,
      company: @company,
      service_type: @service,
      scheduled_at: 3.days.from_now.change(hour: 14, min: 0, sec: 0)
    )

    get confirmation_appointments_path, params: { appointment_id: appt.id }

    assert_response :success
    assert_includes response.body, "Votre reservation est enregistree"
    assert_includes response.body, "Ajouter a mon agenda"
    assert_includes response.body, "Replanifier"
  end

  test "GET reconfirm valide enregistre la reconfirmation" do
    appt = create(:appointment,
      company: @company,
      service_type: @service,
      client_user: create(:user, role: :client),
      scheduled_at: 2.days.from_now,
      status: :confirmed,
      reconfirmation_requested_at: 2.hours.ago
    )
    token = appt.signed_id(purpose: "appointment_reconfirm", expires_in: 7.days)

    get reconfirm_appointment_path(appt), params: { token: token }

    assert_redirected_to appointment_path(appt)
    assert appt.reload.reconfirmed?
  end

  test "GET reconfirm invalide ne modifie pas le rendez-vous" do
    appt = create(:appointment,
      company: @company,
      service_type: @service,
      client_user: create(:user, role: :client),
      scheduled_at: 2.days.from_now,
      status: :confirmed
    )

    get reconfirm_appointment_path(appt), params: { token: "invalid-token" }

    assert_redirected_to root_path
    assert_not appt.reload.reconfirmed?
  end
end
