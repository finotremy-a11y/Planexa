require "test_helper"

class Company::SchedulesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user     = create(:user, :company_admin)
    @company  = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @employee = create(:employee, company: @company)
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_employee_schedules_path(@employee)
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_employee_schedules_path(@employee)
    assert_redirected_to root_path
  end

  test "retourne 404 pour un employé d'une autre entreprise" do
    other_employee = create(:employee, company: create(:company))
    get company_employee_schedules_path(other_employee)
    assert_response :not_found
  end

  # — Index —
  test "GET index retourne 200" do
    get company_employee_schedules_path(@employee)
    assert_response :success
  end

  test "GET index avec des créneaux existants" do
    create(:schedule, employee: @employee, company: @company,
           day_of_week: 1, start_time: "09:00", end_time: "17:00",
           schedule_type: "recurring")
    get company_employee_schedules_path(@employee)
    assert_response :success
  end

  # — Create (créneau récurrent) —
  test "POST create ajoute un créneau récurrent" do
    assert_difference("Schedule.count", 1) do
      post company_employee_schedules_path(@employee), params: {
        schedule: {
          schedule_type: "recurring",
          day_of_week:   2,
          start_time:    "09:00",
          end_time:      "17:00",
          available:     true
        }
      }
    end
    assert_redirected_to company_employee_schedules_path(@employee)
  end

  test "POST create avec paramètres invalides affiche le formulaire" do
    assert_no_difference("Schedule.count") do
      post company_employee_schedules_path(@employee), params: {
        schedule: {
          schedule_type: "recurring",
          day_of_week:   nil,
          start_time:    "09:00",
          end_time:      "09:00"   # end == start → invalide
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create ajoute une exception de planning" do
    assert_difference("Schedule.count", 1) do
      post company_employee_schedules_path(@employee), params: {
        schedule: {
          schedule_type: "exception",
          specific_date: Date.today + 7,
          start_time:    "10:00",
          end_time:      "12:00",
          available:     false
        }
      }
    end
    assert_redirected_to company_employee_schedules_path(@employee)
  end

  # — Destroy —
  test "DELETE destroy supprime un créneau" do
    schedule = create(:schedule, employee: @employee, company: @company,
                      day_of_week: 3, start_time: "08:00", end_time: "12:00",
                      schedule_type: "recurring")
    assert_difference("Schedule.count", -1) do
      delete company_employee_schedule_path(@employee, schedule)
    end
  end

  test "DELETE destroy ne peut pas supprimer un créneau d'une autre entreprise" do
    other_company  = create(:company)
    other_employee = create(:employee, company: other_company)
    other_schedule = create(:schedule, employee: other_employee, company: other_company,
                            day_of_week: 1, start_time: "08:00", end_time: "12:00",
                            schedule_type: "recurring")

    assert_no_difference("Schedule.count") do
      delete company_employee_schedule_path(@employee, other_schedule)
    end
  end
end
