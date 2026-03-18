require "test_helper"

class ServiceTypePolicyTest < ActiveSupport::TestCase
  setup do
    @admin       = create(:user, :admin)
    @owner       = create(:user, :company_admin)
    @company     = create(:company, user: @owner)
    @service     = create(:service_type, company: @company)
    @other_owner = create(:user, :company_admin)
    @other_company = create(:company, user: @other_owner)
    @client = create(:user, role: :client)
  end

  # — index? / show? (public) —
  test "tout le monde peut voir les prestations (public)" do
    assert ServiceTypePolicy.new(nil,     @service).index?
    assert ServiceTypePolicy.new(@client, @service).show?
    assert ServiceTypePolicy.new(@owner,  @service).show?
  end

  # — create? —
  test "owner peut créer une prestation dans sa company" do
    assert ServiceTypePolicy.new(@owner, ServiceType.new(company: @company)).create?
  end

  test "autre owner ne peut pas créer une prestation dans une autre company" do
    assert_not ServiceTypePolicy.new(@other_owner, ServiceType.new(company: @company)).create?
  end

  test "client ne peut pas créer de prestation" do
    assert_not ServiceTypePolicy.new(@client, ServiceType.new(company: @company)).create?
  end

  # — update? —
  test "owner peut modifier sa prestation" do
    assert ServiceTypePolicy.new(@owner, @service).update?
  end

  test "autre owner ne peut pas modifier la prestation" do
    assert_not ServiceTypePolicy.new(@other_owner, @service).update?
  end

  # — destroy? —
  test "owner peut supprimer sa prestation" do
    assert ServiceTypePolicy.new(@owner, @service).destroy?
  end

  test "client ne peut pas supprimer une prestation" do
    assert_not ServiceTypePolicy.new(@client, @service).destroy?
  end

  # — toggle_active? —
  test "owner peut activer/désactiver sa prestation" do
    assert ServiceTypePolicy.new(@owner, @service).toggle_active?
  end

  # — Scope —
  test "scope admin retourne toutes les prestations" do
    services = ServiceTypePolicy::Scope.new(@admin, ServiceType).resolve
    assert_includes services, @service
  end

  test "scope owner retourne uniquement ses prestations" do
    other_service = create(:service_type, company: @other_company)
    services = ServiceTypePolicy::Scope.new(@owner, ServiceType).resolve
    assert_includes     services, @service
    assert_not_includes services, other_service
  end

  test "scope client retourne uniquement les prestations actives" do
    inactive = create(:service_type, company: @company, active: false)
    services = ServiceTypePolicy::Scope.new(@client, ServiceType).resolve
    assert_includes     services, @service
    assert_not_includes services, inactive
  end
end
