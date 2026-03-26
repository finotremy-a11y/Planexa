# frozen_string_literal: true

require "test_helper"

class BookingGroupPolicyTest < ActiveSupport::TestCase
  setup do
    @admin              = create(:user, :admin)
    @company_user       = create(:user, :company_admin)
    @company            = create(:company, user: @company_user)
    @other_company_user = create(:user, :company_admin)
    @other_company      = create(:company, user: @other_company_user)
    @client             = create(:user, role: :client)
    @other_client       = create(:user, role: :client)

    @bg = create(:booking_group, company: @company, client_user: @client,
                 total_amount_cents: 5000, status: :pending)
  end

  # ── show? ────────────────────────────────────────────────────────────────

  test "admin peut voir un booking group" do
    assert BookingGroupPolicy.new(@admin, @bg).show?
  end

  test "company_owner peut voir son booking group" do
    assert BookingGroupPolicy.new(@company_user, @bg).show?
  end

  test "client propriétaire peut voir son booking group" do
    assert BookingGroupPolicy.new(@client, @bg).show?
  end

  test "autre company_admin NE peut PAS voir le booking group" do
    assert_not BookingGroupPolicy.new(@other_company_user, @bg).show?
  end

  test "autre client NE peut PAS voir le booking group" do
    assert_not BookingGroupPolicy.new(@other_client, @bg).show?
  end

  # ── create? ──────────────────────────────────────────────────────────────

  test "n'importe qui peut créer (réservation publique)" do
    assert BookingGroupPolicy.new(nil, BookingGroup.new).create?
    assert BookingGroupPolicy.new(@client, BookingGroup.new).create?
    assert BookingGroupPolicy.new(@company_user, BookingGroup.new).create?
  end

  # ── cancel? ──────────────────────────────────────────────────────────────

  test "admin peut annuler un booking group pending" do
    assert BookingGroupPolicy.new(@admin, @bg).cancel?
  end

  test "company_owner peut annuler son booking group pending" do
    assert BookingGroupPolicy.new(@company_user, @bg).cancel?
  end

  test "client propriétaire peut annuler son booking group pending" do
    assert BookingGroupPolicy.new(@client, @bg).cancel?
  end

  test "personne ne peut annuler un booking group déjà annulé" do
    @bg.update!(status: :cancelled)
    assert_not BookingGroupPolicy.new(@admin, @bg).cancel?
    assert_not BookingGroupPolicy.new(@company_user, @bg).cancel?
    assert_not BookingGroupPolicy.new(@client, @bg).cancel?
  end

  test "personne ne peut annuler un booking group complété" do
    @bg.update!(status: :completed)
    assert_not BookingGroupPolicy.new(@company_user, @bg).cancel?
  end

  test "autre client NE peut PAS annuler un booking group" do
    assert_not BookingGroupPolicy.new(@other_client, @bg).cancel?
  end

  test "autre company NE peut PAS annuler un booking group" do
    assert_not BookingGroupPolicy.new(@other_company_user, @bg).cancel?
  end

  # ── destroy? ─────────────────────────────────────────────────────────────

  test "seul l'admin peut détruire" do
    assert BookingGroupPolicy.new(@admin, @bg).destroy?
    assert_not BookingGroupPolicy.new(@company_user, @bg).destroy?
    assert_not BookingGroupPolicy.new(@client, @bg).destroy?
  end

  # ── Scope ────────────────────────────────────────────────────────────────

  test "scope admin retourne tous les booking groups" do
    other_bg = create(:booking_group, company: @other_company, total_amount_cents: 100)
    scope = BookingGroupPolicy::Scope.new(@admin, BookingGroup.all).resolve
    assert_includes scope, @bg
    assert_includes scope, other_bg
  end

  test "scope company_admin retourne uniquement les booking groups de son entreprise" do
    other_bg = create(:booking_group, company: @other_company, total_amount_cents: 100)
    scope = BookingGroupPolicy::Scope.new(@company_user, BookingGroup.all).resolve
    assert_includes scope, @bg
    assert_not_includes scope, other_bg
  end

  test "scope client retourne uniquement ses propres booking groups" do
    other_bg = create(:booking_group, company: @company, client_user: @other_client,
                      total_amount_cents: 100)
    scope = BookingGroupPolicy::Scope.new(@client, BookingGroup.all).resolve
    assert_includes scope, @bg
    assert_not_includes scope, other_bg
  end
end
