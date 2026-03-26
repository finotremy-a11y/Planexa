require "test_helper"

class ReviewPolicyTest < ActiveSupport::TestCase
  setup do
    @admin        = create(:user, :admin)
    @company_user = create(:user, :company_admin)
    @company      = create(:company, user: @company_user)
    @other_company_user = create(:user, :company_admin)
    @other_company      = create(:company, user: @other_company_user)
    @client       = create(:user, role: :client)
    @service_type = create(:service_type, company: @company)
    @appointment  = create(:appointment, :completed,
      company:     @company,
      service_type: @service_type,
      client_user: @client)
    @review = create(:review, :submitted,
      appointment: @appointment,
      company:     @company,
      client_user: @client)
  end

  # — Admin peut tout —
  test "admin peut voir les avis" do
    assert ReviewPolicy.new(@admin, @review).show?
  end

  test "admin peut supprimer" do
    assert ReviewPolicy.new(@admin, @review).destroy?
  end

  test "admin peut publier" do
    assert ReviewPolicy.new(@admin, @review).publish?
  end

  test "admin peut dépublier" do
    assert ReviewPolicy.new(@admin, @review).unpublish?
  end

  # — Company owner peut voir et supprimer ses propres avis —
  test "company owner peut voir ses avis" do
    assert ReviewPolicy.new(@company_user, @review).show?
  end

  test "company owner peut supprimer ses avis" do
    assert ReviewPolicy.new(@company_user, @review).destroy?
  end

  test "company owner ne peut pas publier/dépublier" do
    assert_not ReviewPolicy.new(@company_user, @review).publish?
    assert_not ReviewPolicy.new(@company_user, @review).unpublish?
  end

  # — Autre company ne peut pas voir les avis —
  test "autre entreprise ne peut pas voir les avis" do
    assert_not ReviewPolicy.new(@other_company_user, @review).show?
  end

  test "client ne peut rien faire via policy" do
    assert_not ReviewPolicy.new(@client, @review).show?
    assert_not ReviewPolicy.new(@client, @review).destroy?
  end
end
