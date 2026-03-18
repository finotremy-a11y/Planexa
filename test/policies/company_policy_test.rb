require "test_helper"

class CompanyPolicyTest < ActiveSupport::TestCase
  setup do
    @admin        = create(:user, :admin)
    @owner        = create(:user, :company_admin)
    @company      = create(:company, user: @owner, status: :active)
    @other_owner  = create(:user, :company_admin)
    @other_company = create(:company, user: @other_owner)
    @client       = create(:user, role: :client)
  end

  # — show? —
  test "tout le monde peut voir une company (fiche publique)" do
    assert CompanyPolicy.new(nil, @company).show?
    assert CompanyPolicy.new(@client, @company).show?
    assert CompanyPolicy.new(@owner, @company).show?
  end

  # — update? —
  test "le owner peut modifier sa company" do
    assert CompanyPolicy.new(@owner, @company).update?
  end

  test "un autre company_admin ne peut pas modifier" do
    assert_not CompanyPolicy.new(@other_owner, @company).update?
  end

  test "un client ne peut pas modifier" do
    assert_not CompanyPolicy.new(@client, @company).update?
  end

  # — manage_employees? —
  test "le owner actif peut gérer ses employés" do
    assert CompanyPolicy.new(@owner, @company).manage_employees?
  end

  test "le owner ne peut pas gérer ses employés si company suspendue" do
    @company.update!(status: :suspended)
    assert_not CompanyPolicy.new(@owner, @company).manage_employees?
  end

  # — manage_settings? —
  test "le owner peut gérer les paramètres" do
    assert CompanyPolicy.new(@owner, @company).manage_settings?
  end

  test "un autre owner ne peut pas gérer les paramètres" do
    assert_not CompanyPolicy.new(@other_owner, @company).manage_settings?
  end

  # — Scope —
  test "scope pour admin retourne toutes les companies" do
    companies = CompanyPolicy::Scope.new(@admin, Company).resolve
    assert_includes companies, @company
    assert_includes companies, @other_company
  end

  test "scope pour company_admin retourne uniquement sa company" do
    companies = CompanyPolicy::Scope.new(@owner, Company).resolve
    assert_includes     companies, @company
    assert_not_includes companies, @other_company
  end

  test "scope pour client ou visiteur retourne les companies actives et publiques" do
    public_company  = create(:company, status: :active)
    private_company = create(:company, status: :active)
    private_company.setting.update!(booking_mode: :booking_private)

    companies = CompanyPolicy::Scope.new(@client, Company).resolve
    assert_includes     companies, public_company
    assert_not_includes companies, private_company
  end
end
