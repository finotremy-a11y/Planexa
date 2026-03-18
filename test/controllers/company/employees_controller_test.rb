require "test_helper"

class Company::EmployeesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @employee = create(:employee, company: @company)
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_employees_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_employees_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get company_employees_path
    assert_response :success
  end

  # — Show —
  test "GET show retourne 200" do
    get company_employee_path(@employee)
    assert_response :success
  end

  test "GET show retourne 404 pour un employé d'une autre entreprise" do
    other_employee = create(:employee, company: create(:company))
    get company_employee_path(other_employee)
    assert_response :not_found
  end

  # — New —
  test "GET new retourne 200" do
    get new_company_employee_path
    assert_response :success
  end

  # — Create —
  test "POST create avec paramètres valides crée un employé" do
    assert_difference("Employee.count", 1) do
      post company_employees_path, params: {
        employee: {
          first_name: "Alice",
          last_name:  "Martin",
          email:      "alice.martin@example.com",
          phone:      "0601020304"
        }
      }
    end
    assert_redirected_to company_employee_path(Employee.last)
  end

  test "POST create avec paramètres invalides affiche le formulaire" do
    assert_no_difference("Employee.count") do
      post company_employees_path, params: {
        employee: { first_name: "", last_name: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  # — Edit —
  test "GET edit retourne 200" do
    get edit_company_employee_path(@employee)
    assert_response :success
  end

  # — Update —
  test "PATCH update avec données valides met à jour l'employé" do
    patch company_employee_path(@employee), params: {
      employee: { first_name: "Bob" }
    }
    assert_equal "Bob", @employee.reload.first_name
    assert_redirected_to company_employee_path(@employee)
  end

  test "PATCH update avec données invalides affiche le formulaire" do
    patch company_employee_path(@employee), params: {
      employee: { first_name: "" }
    }
    assert_response :unprocessable_entity
  end

  # — Destroy —
  test "DELETE destroy supprime l'employé" do
    assert_difference("Employee.count", -1) do
      delete company_employee_path(@employee)
    end
    assert_redirected_to company_employees_path
  end

  # — Toggle active —
  test "PATCH toggle_active désactive un employé actif" do
    @employee.update!(active: true)
    patch toggle_active_company_employee_path(@employee)
    assert_not @employee.reload.active?
    assert_redirected_to company_employees_path
  end

  test "PATCH toggle_active active un employé inactif" do
    @employee.update!(active: false)
    patch toggle_active_company_employee_path(@employee)
    assert @employee.reload.active?
  end
end
