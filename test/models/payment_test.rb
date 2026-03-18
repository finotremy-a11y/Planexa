require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  # — Validations —
  test "invalide sans stripe_payment_intent_id" do
    payment = build(:payment, stripe_payment_intent_id: nil)
    assert_not payment.valid?
    assert payment.errors[:stripe_payment_intent_id].any?
  end

  test "invalide si amount_cents est zéro" do
    payment = build(:payment, amount_cents: 0)
    assert_not payment.valid?
  end

  test "invalide si amount_cents est négatif" do
    payment = build(:payment, amount_cents: -100)
    assert_not payment.valid?
  end

  test "invalide si stripe_payment_intent_id en doublon" do
    create(:payment, stripe_payment_intent_id: "pi_unique_test")
    dup = build(:payment, stripe_payment_intent_id: "pi_unique_test")
    assert_not dup.valid?
    assert dup.errors[:stripe_payment_intent_id].any?
  end

  test "valide avec des attributs corrects" do
    payment = build(:payment)
    assert payment.valid?
  end

  # — Enums —
  test "statut par défaut est pending" do
    payment = create(:payment)
    assert payment.pending?
  end

  test "statut succeeded" do
    payment = create(:payment, :succeeded)
    assert payment.succeeded?
  end

  test "statut failed" do
    payment = create(:payment, :failed)
    assert payment.failed?
  end

  test "statut refunded" do
    payment = create(:payment, :refunded)
    assert payment.refunded?
  end

  # — Scopes —
  test "scope successful ne retourne que les paiements réussis" do
    succeeded = create(:payment, :succeeded)
    pending   = create(:payment)
    assert_includes Payment.successful, succeeded
    assert_not_includes Payment.successful, pending
  end

  # — Associations —
  test "appartient à un appointment" do
    payment = create(:payment)
    assert_respond_to payment, :appointment
    assert_not_nil payment.appointment
  end

  test "appartient à un client_user" do
    payment = create(:payment)
    assert_respond_to payment, :client_user
    assert_not_nil payment.client_user
  end

  test "appartient à une company" do
    payment = create(:payment)
    assert_respond_to payment, :company
    assert_not_nil payment.company
  end
end
