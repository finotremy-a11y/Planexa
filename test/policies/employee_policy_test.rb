require "test_helper"

class EmployeePolicyTest < ActiveSupport::TestCase
  setup do
    @admin       = create(:user, :admin)
    @owner       = create(:user, :company_admin)
    @company     = create(:company, user: @owner)
    @employee    = create(:employee, company: @company)

    @other_owner = create(:user, :company_admin)
    @other_company = create(:company, user: @other_owner)
    @client = create(:user, role: :client)
  end

  # — index? / show? —
  test "owner peut lister ses employés" do
    assert EmployeePolicy.new(@owner, @employee).index?
  end

  test "autre owner ne peut pas lister les employés" do
    assert_not EmployeePolicy.new(@other_owner, @employee).index?
  end

  test "client ne peut pas lister les employés" do
    assert_not EmployeePolicy.new(@client, @employee).index?
  end

  test "owner peut voir un employé" do
    assert EmployeePolicy.new(@owner, @employee).show?
  end

  # — create? / update? / destroy? —
  test "owner peut créer un employé" do
    assert EmployeePolicy.new(@owner, Employee.new(company: @company)).create?
  end

  test "autre owner ne peut pas créer un employé dans une autre company" do
    assert_not EmployeePolicy.new(@other_owner, Employee.new(company: @company)).create?
  end

  test "owner peut modifier un employé" do
    assert EmployeePolicy.new(@owner, @employee).update?
  end

  test "owner peut supprimer un employé" do
    assert EmployeePolicy.new(@owner, @employee).destroy?
  end

  test "autre owner ne peut pas supprimer l'employé" do
    assert_not EmployeePolicy.new(@other_owner, @employee).destroy?
  end

  # — toggle_active? —
  test "owner peut activer/désactiver un employé" do
    assert EmployeePolicy.new(@owner, @employee).toggle_active?
  end

  # L'admin accède aux employés via ses propres controllers (sans passer par Pundit),
  # donc la policy ne lui donne pas accès directement — c'est intentionnel.
  test "admin ne peut pas modifier un employé d'une autre company via la policy" do
    assert_not EmployeePolicy.new(@admin, @employee).update?
    assert_not EmployeePolicy.new(@admin, @employee).destroy?
  end

  test "admin peut voir tous les employés via le scope" do
    employees = EmployeePolicy::Scope.new(@admin, Employee).resolve
    assert_includes employees, @employee
  end

  # — Scope —
  test "scope admin retourne tous les employés" do
    employees = EmployeePolicy::Scope.new(@admin, Employee).resolve
    assert_includes employees, @employee
  end

  test "scope owner retourne uniquement ses employés" do
    other_emp = create(:employee, company: @other_company)
    employees = EmployeePolicy::Scope.new(@owner, Employee).resolve
    assert_includes     employees, @employee
    assert_not_includes employees, other_emp
  end

  test "scope client retourne aucun employé" do
    employees = EmployeePolicy::Scope.new(@client, Employee).resolve
    assert_equal 0, employees.count
  end
end
