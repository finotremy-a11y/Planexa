# frozen_string_literal: true

require "test_helper"

class LoyaltyPointTest < ActiveSupport::TestCase
  # ── Validations ────────────────────────────────────────────────────────────
  test "valide avec attributs corrects" do
    lp = build(:loyalty_point)
    assert lp.valid?
  end

  test "invalide sans points" do
    lp = build(:loyalty_point, points: nil)
    assert_not lp.valid?
    assert lp.errors[:points].any?
  end

  test "invalide avec points à zéro" do
    lp = build(:loyalty_point, points: 0)
    assert_not lp.valid?
    assert lp.errors[:points].any?
  end

  test "valide avec points négatifs (redeemed)" do
    lp = build(:loyalty_point, :redeemed)
    assert lp.valid?
  end

  test "invalide avec reason inconnue" do
    lp = build(:loyalty_point, reason: "unknown")
    assert_not lp.valid?
    assert lp.errors[:reason].any?
  end

  test "valide avec chaque reason autorisée" do
    LoyaltyPoint::REASONS.each do |reason|
      pts = reason == "redeemed" ? -10 : 10
      lp = build(:loyalty_point, reason: reason, points: pts)
      assert lp.valid?, "Devrait être valide avec reason=#{reason}"
    end
  end

  # ── Associations ───────────────────────────────────────────────────────────
  test "appartient à un client_user" do
    lp = create(:loyalty_point)
    assert_not_nil lp.client_user
  end

  test "appartient à une company" do
    lp = create(:loyalty_point)
    assert_not_nil lp.company
  end

  test "appointment est optionnel" do
    lp = build(:loyalty_point, appointment: nil)
    assert lp.valid?
  end

  # ── Scopes ─────────────────────────────────────────────────────────────────
  test "scope earned retourne uniquement les points gagnés" do
    company = create(:company)
    client  = create(:user)
    create(:loyalty_point, client_user: client, company: company, reason: "earned", points: 10)
    create(:loyalty_point, client_user: client, company: company, reason: "redeemed", points: -5)

    result = LoyaltyPoint.earned
    assert result.all? { |lp| lp.reason == "earned" }
  end

  test "scope redeemed retourne uniquement les points déduits" do
    company = create(:company)
    client  = create(:user)
    create(:loyalty_point, client_user: client, company: company, reason: "earned", points: 10)
    redeemed = create(:loyalty_point, client_user: client, company: company, reason: "redeemed", points: -5)

    result = LoyaltyPoint.redeemed
    assert_includes result, redeemed
    assert result.all? { |lp| lp.reason == "redeemed" }
  end

  test "scope for_company filtre par entreprise" do
    company1 = create(:company)
    company2 = create(:company)
    client   = create(:user)
    lp1 = create(:loyalty_point, client_user: client, company: company1)
    lp2 = create(:loyalty_point, client_user: client, company: company2)

    result = LoyaltyPoint.for_company(company1)
    assert_includes result, lp1
    assert_not_includes result, lp2
  end

  # ── Class methods ──────────────────────────────────────────────────────────
  test "balance_for calcule la somme des points pour un client et une entreprise" do
    company = create(:company)
    client  = create(:user)
    create(:loyalty_point, client_user: client, company: company, points: 10, reason: "earned")
    create(:loyalty_point, client_user: client, company: company, points: 10, reason: "earned")
    create(:loyalty_point, client_user: client, company: company, points: -5, reason: "redeemed")

    assert_equal 15, LoyaltyPoint.balance_for(client, company)
  end

  test "balance_for retourne 0 si aucun point" do
    company = create(:company)
    client  = create(:user)
    assert_equal 0, LoyaltyPoint.balance_for(client, company)
  end

  test "balance_for ne mélange pas les entreprises" do
    company1 = create(:company)
    company2 = create(:company)
    client   = create(:user)
    create(:loyalty_point, client_user: client, company: company1, points: 10, reason: "earned")
    create(:loyalty_point, client_user: client, company: company2, points: 20, reason: "earned")

    assert_equal 10, LoyaltyPoint.balance_for(client, company1)
    assert_equal 20, LoyaltyPoint.balance_for(client, company2)
  end
end
