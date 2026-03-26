# frozen_string_literal: true

require "test_helper"

class Company::EmployeeAbsencesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user     = create(:user, :company_admin)
    @company  = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @employee = create(:employee, company: @company)
    @absence  = create(:employee_absence, employee: @employee)
  end

  # ── Autorisation ───────────────────────────────────────────────────────────
  test "redirige si non connecté" do
    sign_out @user
    get company_employee_employee_absences_path(@employee)
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_employee_employee_absences_path(@employee)
    assert_redirected_to root_path
  end

  test "404 si employé d'une autre entreprise" do
    other_employee = create(:employee, company: create(:company))
    get company_employee_employee_absences_path(other_employee)
    assert_response :not_found
  end

  # ── Index ──────────────────────────────────────────────────────────────────
  test "GET index retourne 200" do
    get company_employee_employee_absences_path(@employee)
    assert_response :success
  end

  # ── New ────────────────────────────────────────────────────────────────────
  test "GET new retourne 200" do
    get new_company_employee_employee_absence_path(@employee)
    assert_response :success
  end

  # ── Create ─────────────────────────────────────────────────────────────────
  test "POST create avec paramètres valides crée une absence" do
    assert_difference("EmployeeAbsence.count", 1) do
      post company_employee_employee_absences_path(@employee), params: {
        employee_absence: {
          starts_at: 5.days.from_now.iso8601,
          ends_at:   7.days.from_now.iso8601,
          reason:    "vacation",
          note:      "Congés annuels"
        }
      }
    end
    assert_redirected_to company_employee_employee_absences_path(@employee)
    assert_match(/Absence ajoutée/, flash[:notice])
  end

  test "POST create avec paramètres invalides retourne 422" do
    assert_no_difference("EmployeeAbsence.count") do
      post company_employee_employee_absences_path(@employee), params: {
        employee_absence: {
          starts_at: nil,
          ends_at:   nil,
          reason:    "vacation"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── Edit ───────────────────────────────────────────────────────────────────
  test "GET edit retourne 200" do
    get edit_company_employee_employee_absence_path(@employee, @absence)
    assert_response :success
  end

  test "GET edit retourne 404 pour absence d'un autre employé" do
    other_employee = create(:employee, company: @company)
    other_absence  = create(:employee_absence, employee: other_employee)
    get edit_company_employee_employee_absence_path(@employee, other_absence)
    assert_response :not_found
  end

  # ── Update ─────────────────────────────────────────────────────────────────
  test "PATCH update avec paramètres valides met à jour l'absence" do
    patch company_employee_employee_absence_path(@employee, @absence), params: {
      employee_absence: { reason: "sick" }
    }
    assert_redirected_to company_employee_employee_absences_path(@employee)
    assert_equal "sick", @absence.reload.reason
  end

  test "PATCH update avec paramètres invalides retourne 422" do
    patch company_employee_employee_absence_path(@employee, @absence), params: {
      employee_absence: { starts_at: nil }
    }
    assert_response :unprocessable_entity
  end

  # ── Destroy ────────────────────────────────────────────────────────────────
  test "DELETE destroy supprime l'absence" do
    assert_difference("EmployeeAbsence.count", -1) do
      delete company_employee_employee_absence_path(@employee, @absence)
    end
    assert_redirected_to company_employee_employee_absences_path(@employee)
  end
end
