require "test_helper"

class PaymentPolicyTest < ActiveSupport::TestCase
  setup do
    @admin       = create(:user, :admin)
    @owner       = create(:user, :company_admin)
    @company     = create(:company, user: @owner)
    @client      = create(:user, role: :client)
    @service     = create(:service_type, company: @company)
    @appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client)
    @payment = create(:payment,
      appointment:  @appointment,
      client_user:  @client,
      company:      @company)

    @other_client = create(:user, role: :client)
    @other_owner  = create(:user, :company_admin)
    create(:company, user: @other_owner)
  end

  # — show? —
  test "admin peut voir n'importe quel paiement" do
    assert PaymentPolicy.new(@admin, @payment).show?
  end

  test "le client propriétaire peut voir son paiement" do
    assert PaymentPolicy.new(@client, @payment).show?
  end

  test "l'entreprise propriétaire peut voir le paiement" do
    assert PaymentPolicy.new(@owner, @payment).show?
  end

  test "un autre client ne peut pas voir le paiement" do
    assert_not PaymentPolicy.new(@other_client, @payment).show?
  end

  test "un autre owner ne peut pas voir le paiement" do
    assert_not PaymentPolicy.new(@other_owner, @payment).show?
  end

  # — create? / update? —
  test "personne ne peut créer un paiement via l'UI" do
    assert_not PaymentPolicy.new(@admin, @payment).create?
    assert_not PaymentPolicy.new(@owner, @payment).create?
    assert_not PaymentPolicy.new(@client, @payment).create?
  end

  test "personne ne peut modifier un paiement" do
    assert_not PaymentPolicy.new(@admin, @payment).update?
    assert_not PaymentPolicy.new(@owner, @payment).update?
    assert_not PaymentPolicy.new(@client, @payment).update?
  end

  # — destroy? —
  test "seul l'admin peut supprimer un paiement" do
    assert      PaymentPolicy.new(@admin,  @payment).destroy?
    assert_not  PaymentPolicy.new(@owner,  @payment).destroy?
    assert_not  PaymentPolicy.new(@client, @payment).destroy?
  end

  # — Scope —
  test "scope admin retourne tous les paiements" do
    payments = PaymentPolicy::Scope.new(@admin, Payment).resolve
    assert_includes payments, @payment
  end

  test "scope owner retourne les paiements de sa company" do
    other_client  = create(:user, role: :client)
    other_payment = create(:payment,
      appointment:  create(:appointment, company: @company, service_type: @service, client_user: other_client),
      client_user:  other_client,
      company:      @company)

    payments = PaymentPolicy::Scope.new(@owner, Payment).resolve
    assert_includes payments, @payment
    assert_includes payments, other_payment
  end

  test "scope client retourne uniquement ses propres paiements" do
    payments = PaymentPolicy::Scope.new(@client, Payment).resolve
    assert_includes payments, @payment
  end
end
