# frozen_string_literal: true

require "test_helper"

class DiscountCodeTest < ActiveSupport::TestCase
  # ── Validations ────────────────────────────────────────────────────────────
  test "valide avec attributs corrects" do
    code = build(:discount_code)
    assert code.valid?
  end

  test "invalide sans discount_value_cents" do
    code = build(:discount_code, discount_value_cents: nil)
    assert_not code.valid?
    assert code.errors[:discount_value_cents].any?
  end

  test "invalide avec discount_value_cents à zéro" do
    code = build(:discount_code, discount_value_cents: 0)
    assert_not code.valid?
    assert code.errors[:discount_value_cents].any?
  end

  test "invalide sans expires_at" do
    code = build(:discount_code, expires_at: nil)
    assert_not code.valid?
    assert code.errors[:expires_at].any?
  end

  test "code est généré automatiquement" do
    code = create(:discount_code)
    assert code.code.present?
    assert code.code.start_with?("FIDELITE-")
  end

  test "code est unique" do
    existing = create(:discount_code)
    duplicate = build(:discount_code, code: existing.code)
    assert_not duplicate.valid?
    assert duplicate.errors[:code].any?
  end

  # ── Enums ──────────────────────────────────────────────────────────────────
  test "discount_type percentage" do
    code = build(:discount_code, :percentage)
    assert code.percentage?
  end

  test "discount_type fixed" do
    code = build(:discount_code, discount_type: :fixed)
    assert code.fixed?
  end

  # ── Scopes ─────────────────────────────────────────────────────────────────
  test "scope usable retourne les codes utilisables" do
    company = create(:company)
    client  = create(:user)
    usable  = create(:discount_code, company: company, client_user: client)
    used    = create(:discount_code, :used, company: company, client_user: client)
    expired = create(:discount_code, :expired, company: company, client_user: client)

    result = DiscountCode.usable
    assert_includes result, usable
    assert_not_includes result, used
    assert_not_includes result, expired
  end

  test "scope used retourne les codes utilisés" do
    company = create(:company)
    client  = create(:user)
    usable  = create(:discount_code, company: company, client_user: client)
    used    = create(:discount_code, :used, company: company, client_user: client)

    result = DiscountCode.used
    assert_includes result, used
    assert_not_includes result, usable
  end

  test "scope expired retourne les codes expirés non utilisés" do
    company = create(:company)
    client  = create(:user)
    usable  = create(:discount_code, company: company, client_user: client)
    expired = create(:discount_code, :expired, company: company, client_user: client)

    result = DiscountCode.expired
    assert_includes result, expired
    assert_not_includes result, usable
  end

  test "scope for_company filtre par entreprise" do
    company1 = create(:company)
    company2 = create(:company)
    client   = create(:user)
    code1 = create(:discount_code, company: company1, client_user: client)
    code2 = create(:discount_code, company: company2, client_user: client)

    result = DiscountCode.for_company(company1)
    assert_includes result, code1
    assert_not_includes result, code2
  end

  # ── Instance methods ───────────────────────────────────────────────────────
  test "usable? retourne true si non utilisé et non expiré" do
    code = build(:discount_code)
    assert code.usable?
  end

  test "usable? retourne false si utilisé" do
    code = build(:discount_code, :used)
    assert_not code.usable?
  end

  test "usable? retourne false si expiré" do
    code = build(:discount_code, :expired)
    assert_not code.usable?
  end

  test "used? retourne true si used_at présent" do
    code = build(:discount_code, :used)
    assert code.used?
  end

  test "used? retourne false si used_at nil" do
    code = build(:discount_code)
    assert_not code.used?
  end

  test "expired? retourne true si expiré et non utilisé" do
    code = build(:discount_code, :expired)
    assert code.expired?
  end

  test "expired? retourne false si non expiré" do
    code = build(:discount_code)
    assert_not code.expired?
  end

  test "use! marque le code comme utilisé" do
    code = create(:discount_code)
    assert code.usable?
    code.use!
    assert code.used?
  end

  test "discount_display pour fixed" do
    code = build(:discount_code, discount_type: :fixed, discount_value_cents: 1000)
    assert_match "10", code.discount_display
    assert_match "€", code.discount_display
  end

  test "discount_display pour percentage" do
    code = build(:discount_code, :percentage, discount_value_cents: 1500)
    assert_equal "15%", code.discount_display
  end
end
