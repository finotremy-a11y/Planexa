# frozen_string_literal: true

require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  # — Validations —
  test "valide avec des attributs corrects" do
    invoice = build(:invoice)
    assert invoice.valid?
  end

  test "invalide sans issued_at" do
    invoice = build(:invoice, issued_at: nil)
    assert_not invoice.valid?
    assert invoice.errors[:issued_at].any?
  end

  test "invalide si subtotal_cents négatif" do
    invoice = build(:invoice, subtotal_cents: -1)
    assert_not invoice.valid?
  end

  test "invalide si tax_amount_cents négatif" do
    invoice = build(:invoice, tax_amount_cents: -1)
    assert_not invoice.valid?
  end

  test "invalide si total_cents négatif" do
    invoice = build(:invoice, total_cents: -1)
    assert_not invoice.valid?
  end

  test "invalide si tax_rate supérieur à 1" do
    invoice = build(:invoice, tax_rate: 1.5)
    assert_not invoice.valid?
  end

  test "invalide si tax_rate négatif" do
    invoice = build(:invoice, tax_rate: -0.1)
    assert_not invoice.valid?
  end

  test "invalide si invoice_number en doublon" do
    existing = create(:invoice)
    dup = build(:invoice, invoice_number: existing.invoice_number)
    assert_not dup.valid?
    assert dup.errors[:invoice_number].any?
  end

  # — Génération automatique du numéro —
  test "génère automatiquement un invoice_number au format FAC-YYYY-NNNN" do
    invoice = create(:invoice)
    assert_match(/\AFAC-\d{4}-\d{4}\z/, invoice.invoice_number)
  end

  test "incrémente le numéro séquentiel" do
    inv1 = create(:invoice)
    inv2 = create(:invoice)
    seq1 = inv1.invoice_number.split("-").last.to_i
    seq2 = inv2.invoice_number.split("-").last.to_i
    assert_equal seq1 + 1, seq2
  end

  # — Associations —
  test "appartient à un payment" do
    invoice = create(:invoice)
    assert_respond_to invoice, :payment
    assert_not_nil invoice.payment
  end

  test "appartient à une company" do
    invoice = create(:invoice)
    assert_respond_to invoice, :company
    assert_not_nil invoice.company
  end

  test "client_user est optionnel" do
    invoice = build(:invoice, client_user: nil)
    assert invoice.valid?
  end

  # — Scopes —
  test "scope for_company filtre par entreprise" do
    company1 = create(:company)
    company2 = create(:company)
    inv1 = create(:invoice, company: company1)
    inv2 = create(:invoice, company: company2)
    assert_includes Invoice.for_company(company1), inv1
    assert_not_includes Invoice.for_company(company1), inv2
  end

  test "scope for_client filtre par client" do
    client1 = create(:user, role: :client)
    client2 = create(:user, role: :client)
    inv1 = create(:invoice, client_user: client1)
    inv2 = create(:invoice, client_user: client2)
    assert_includes Invoice.for_client(client1), inv1
    assert_not_includes Invoice.for_client(client1), inv2
  end

  test "scope for_month filtre par mois" do
    inv_march = create(:invoice, issued_at: Date.new(2026, 3, 15).to_time)
    inv_april = create(:invoice, issued_at: Date.new(2026, 4, 10).to_time)
    result = Invoice.for_month(2026, 3)
    assert_includes result, inv_march
    assert_not_includes result, inv_april
  end

  test "scope recent trie par date décroissante" do
    old = create(:invoice, issued_at: 2.days.ago)
    recent = create(:invoice, issued_at: 1.day.ago)
    assert_equal recent, Invoice.recent.first
  end

  # — Active Storage —
  test "peut attacher un PDF" do
    invoice = create(:invoice, :with_pdf)
    assert invoice.pdf.attached?
  end
end
