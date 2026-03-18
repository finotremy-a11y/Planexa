require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  # — Validations —
  test "invalide sans first_name" do
    employee = build(:employee, first_name: nil)
    assert_not employee.valid?
    assert employee.errors[:first_name].any?
  end

  test "invalide sans last_name" do
    employee = build(:employee, last_name: nil)
    assert_not employee.valid?
    assert employee.errors[:last_name].any?
  end

  test "valide avec attributs corrects" do
    employee = build(:employee)
    assert employee.valid?
  end

  # — Méthodes —
  test "full_name retourne prénom + nom" do
    employee = build(:employee, first_name: "Jean", last_name: "Dupont")
    assert_equal "Jean Dupont", employee.full_name
  end

  test "available_at? retourne false si pas d'horaires configurés" do
    employee = create(:employee)
    # Pas de schedule configuré → indisponible
    assert_not employee.available_at?(Time.current, 60)
  end

  # — Scopes —
  test "scope active ne retourne que les employés actifs" do
    active   = create(:employee, active: true)
    inactive = create(:employee, active: false)
    assert_includes Employee.active, active
    assert_not_includes Employee.active, inactive
  end

  test "scope skilled_for retourne les employés ayant la compétence" do
    company      = create(:company)
    service_type = create(:service_type, company: company)
    skilled      = create(:employee, company: company)
    unskilled    = create(:employee, company: company)
    create(:employee_skill, employee: skilled, service_type: service_type)

    assert_includes Employee.skilled_for(service_type), skilled
    assert_not_includes Employee.skilled_for(service_type), unskilled
  end

  # — Associations —
  test "appartient à une company" do
    employee = create(:employee)
    assert_not_nil employee.company
  end

  test "a plusieurs employee_skills" do
    employee = create(:employee)
    assert_respond_to employee, :employee_skills
  end

  test "a plusieurs schedules" do
    employee = create(:employee)
    assert_respond_to employee, :schedules
  end
end
