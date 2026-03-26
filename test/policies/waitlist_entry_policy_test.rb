require "test_helper"

class WaitlistEntryPolicyTest < ActiveSupport::TestCase
  setup do
    @company   = create(:company)
    @admin_user = create(:user, :admin)
    @company_admin = @company.user
    @other_admin = create(:user, :company_admin)
    @client    = create(:user, role: :client)
    @entry     = create(:waitlist_entry, company: @company)
  end

  # — Admin —
  test "admin can index waitlist entries" do
    assert WaitlistEntryPolicy.new(@admin_user, @entry).index?
  end

  test "admin can show waitlist entry" do
    assert WaitlistEntryPolicy.new(@admin_user, @entry).show?
  end

  test "admin can destroy waitlist entry" do
    assert WaitlistEntryPolicy.new(@admin_user, @entry).destroy?
  end

  # — Company owner —
  test "company owner can index their waitlist entries" do
    assert WaitlistEntryPolicy.new(@company_admin, @entry).index?
  end

  test "company owner can show their waitlist entry" do
    assert WaitlistEntryPolicy.new(@company_admin, @entry).show?
  end

  test "company owner can destroy their waitlist entry" do
    assert WaitlistEntryPolicy.new(@company_admin, @entry).destroy?
  end

  # — Other company admin (different company) —
  test "other company admin cannot index" do
    assert_not WaitlistEntryPolicy.new(@other_admin, @entry).index?
  end

  test "other company admin cannot show" do
    assert_not WaitlistEntryPolicy.new(@other_admin, @entry).show?
  end

  test "other company admin cannot destroy" do
    assert_not WaitlistEntryPolicy.new(@other_admin, @entry).destroy?
  end

  # — Client —
  test "client cannot index waitlist entries" do
    assert_not WaitlistEntryPolicy.new(@client, @entry).index?
  end

  test "client cannot show waitlist entry" do
    assert_not WaitlistEntryPolicy.new(@client, @entry).show?
  end

  test "client cannot destroy waitlist entry" do
    assert_not WaitlistEntryPolicy.new(@client, @entry).destroy?
  end

  # — Scope —
  test "admin scope returns all entries" do
    other_entry = create(:waitlist_entry)
    scope = WaitlistEntryPolicy::Scope.new(@admin_user, WaitlistEntry).resolve
    assert_includes scope, @entry
    assert_includes scope, other_entry
  end

  test "company admin scope returns only their company's entries" do
    other_entry = create(:waitlist_entry)
    scope = WaitlistEntryPolicy::Scope.new(@company_admin, WaitlistEntry).resolve
    assert_includes scope, @entry
    assert_not_includes scope, other_entry
  end

  test "client scope returns nothing" do
    scope = WaitlistEntryPolicy::Scope.new(@client, WaitlistEntry).resolve
    assert_empty scope
  end
end
