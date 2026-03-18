require "test_helper"

class SubscriptionPolicyTest < ActiveSupport::TestCase
  setup do
    @admin       = create(:user, :admin)
    @owner       = create(:user, :company_admin)
    @company     = create(:company, user: @owner)
    @subscription = create(:subscription, company: @company, status: :active)

    @other_owner = create(:user, :company_admin)
    @other_company = create(:company, user: @other_owner)
    @client = create(:user, role: :client)
  end

  # — show? —
  test "owner peut voir son abonnement" do
    assert SubscriptionPolicy.new(@owner, @subscription).show?
  end

  test "admin peut voir tous les abonnements" do
    assert SubscriptionPolicy.new(@admin, @subscription).show?
  end

  test "autre owner ne peut pas voir l'abonnement" do
    assert_not SubscriptionPolicy.new(@other_owner, @subscription).show?
  end

  test "client ne peut pas voir les abonnements" do
    assert_not SubscriptionPolicy.new(@client, @subscription).show?
  end

  # — create? —
  test "owner peut créer un abonnement si aucun n'existe" do
    # Utiliser un owner/company sans abonnement existant
    fresh_owner   = create(:user, :company_admin)
    fresh_company = create(:company, user: fresh_owner)
    fresh_owner.reload  # Rafraîchir l'association company
    new_sub = Subscription.new(company: fresh_company)
    assert SubscriptionPolicy.new(fresh_owner, new_sub).create?
  end

  test "owner ne peut pas créer un second abonnement actif" do
    new_sub = Subscription.new(company: @company)
    assert_not SubscriptionPolicy.new(@owner, new_sub).create?
  end

  test "autre owner ne peut pas créer un abonnement pour une autre company" do
    new_sub = Subscription.new(company: @company)
    assert_not SubscriptionPolicy.new(@other_owner, new_sub).create?
  end

  # — destroy? —
  test "admin peut annuler n'importe quel abonnement" do
    assert SubscriptionPolicy.new(@admin, @subscription).destroy?
  end

  test "owner peut annuler son abonnement" do
    assert SubscriptionPolicy.new(@owner, @subscription).destroy?
  end

  test "client ne peut pas annuler un abonnement" do
    assert_not SubscriptionPolicy.new(@client, @subscription).destroy?
  end
end
