require "test_helper"

class Company::EmployeeSkillsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user         = create(:user, :company_admin)
    @company      = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @employee     = create(:employee, company: @company)
    @service_type = create(:service_type, company: @company, active: true)
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_employee_skills_path(@employee)
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_employee_skills_path(@employee)
    assert_redirected_to root_path
  end

  test "retourne 404 pour un employé d'une autre entreprise" do
    other_employee = create(:employee, company: create(:company))
    get company_employee_skills_path(other_employee)
    assert_response :not_found
  end

  # — Index —
  test "GET index retourne 200" do
    get company_employee_skills_path(@employee)
    assert_response :success
  end

  test "GET index liste les aptitudes de l'employé" do
    create(:employee_skill, employee: @employee, service_type: @service_type)
    get company_employee_skills_path(@employee)
    assert_response :success
  end

  # — Create —
  test "POST create ajoute une aptitude" do
    assert_difference("EmployeeSkill.count", 1) do
      post company_employee_skills_path(@employee), params: {
        employee_skill: { service_type_id: @service_type.id }
      }
    end
    assert_redirected_to company_employee_skills_path(@employee)
    assert_match "ajoutée", flash[:notice]
  end

  test "POST create avec paramètres invalides redirige avec alerte" do
    assert_no_difference("EmployeeSkill.count") do
      post company_employee_skills_path(@employee), params: {
        employee_skill: { service_type_id: nil }
      }
    end
    assert_redirected_to company_employee_skills_path(@employee)
    assert flash[:alert].present?
  end

  test "POST create ne peut pas ajouter une aptitude d'une autre entreprise" do
    other_service = create(:service_type, company: create(:company))
    assert_no_difference("EmployeeSkill.count") do
      post company_employee_skills_path(@employee), params: {
        employee_skill: { service_type_id: other_service.id }
      }
    end
    assert_redirected_to company_employee_skills_path(@employee)
    assert_match "introuvable", flash[:alert]
  end

  # — Destroy —
  test "DELETE destroy supprime une aptitude" do
    skill = create(:employee_skill, employee: @employee, service_type: @service_type)
    assert_difference("EmployeeSkill.count", -1) do
      delete company_employee_skill_path(@employee, skill)
    end
    assert_redirected_to company_employee_skills_path(@employee)
    assert_match "supprimée", flash[:notice]
  end

  test "DELETE destroy ne peut pas supprimer une aptitude d'un autre employé" do
    other_employee = create(:employee, company: create(:company))
    other_service  = create(:service_type, company: other_employee.company)
    other_skill    = create(:employee_skill, employee: other_employee, service_type: other_service)

    assert_no_difference("EmployeeSkill.count") do
      delete company_employee_skill_path(@employee, other_skill)
    end
  end
end
