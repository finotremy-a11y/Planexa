require "test_helper"

class WaitlistEntryTest < ActiveSupport::TestCase
  # ── Validations ────────────────────────────────────────────────────────────

  test "valid with client_name and client_email (guest)" do
    entry = build(:waitlist_entry)
    assert entry.valid?
  end

  test "valid with client_user (authenticated user)" do
    entry = build(:waitlist_entry, :with_client)
    assert entry.valid?
  end

  test "invalid without client info and without client_user" do
    entry = build(:waitlist_entry, client_name: nil, client_email: nil, client_user: nil)
    assert_not entry.valid?
    assert entry.errors[:base].any?
  end

  test "invalid with bad email format" do
    entry = build(:waitlist_entry, client_email: "invalid-email")
    assert_not entry.valid?
    assert entry.errors[:client_email].any?
  end

  test "generates token automatically" do
    entry = build(:waitlist_entry, token: nil)
    entry.valid?
    assert entry.token.present?
  end

  test "token must be unique" do
    existing = create(:waitlist_entry)
    duplicate = build(:waitlist_entry, token: existing.token)
    assert_not duplicate.valid?
    assert duplicate.errors[:token].any?
  end

  test "populates email and name from client_user on create" do
    user = create(:user, first_name: "Jean", last_name: "Dupont", email: "jean@test.com")
    entry = create(:waitlist_entry, client_user: user, client_email: nil, client_name: nil)
    assert_equal "jean@test.com", entry.client_email
    assert_equal "Jean Dupont", entry.client_name
  end

  # ── Scopes ─────────────────────────────────────────────────────────────────

  test "scope pending returns non-notified non-expired entries" do
    pending_entry  = create(:waitlist_entry)
    notified_entry = create(:waitlist_entry, :notified)
    expired_entry  = create(:waitlist_entry, :expired)

    assert_includes WaitlistEntry.pending, pending_entry
    assert_not_includes WaitlistEntry.pending, notified_entry
    assert_not_includes WaitlistEntry.pending, expired_entry
  end

  test "scope notified returns entries that are notified but not expired" do
    pending_entry  = create(:waitlist_entry)
    notified_entry = create(:waitlist_entry, :notified)
    expired_entry  = create(:waitlist_entry, :expired)

    assert_includes WaitlistEntry.notified, notified_entry
    assert_not_includes WaitlistEntry.notified, pending_entry
    assert_not_includes WaitlistEntry.notified, expired_entry
  end

  test "scope expired returns expired entries" do
    pending_entry = create(:waitlist_entry)
    expired_entry = create(:waitlist_entry, :expired)

    assert_includes WaitlistEntry.expired, expired_entry
    assert_not_includes WaitlistEntry.expired, pending_entry
  end

  test "scope active returns non-expired entries" do
    pending_entry  = create(:waitlist_entry)
    notified_entry = create(:waitlist_entry, :notified)
    expired_entry  = create(:waitlist_entry, :expired)

    assert_includes WaitlistEntry.active, pending_entry
    assert_includes WaitlistEntry.active, notified_entry
    assert_not_includes WaitlistEntry.active, expired_entry
  end

  test "scope next_in_line prioritizes preferred date then fifo" do
    company = create(:company)
    service = create(:service_type, company: company)
    target_date = 5.days.from_now.to_date

    matching_date = create(:waitlist_entry, company: company, service_type: service,
                                            preferred_date: target_date, created_at: 1.hour.ago)
    no_preference = create(:waitlist_entry, company: company, service_type: service,
                                            preferred_date: nil, created_at: 2.hours.ago)
    other_date = create(:waitlist_entry, company: company, service_type: service,
                                         preferred_date: target_date + 1.day, created_at: 3.hours.ago)
    _notified = create(:waitlist_entry, :notified, company: company, service_type: service)

    result = WaitlistEntry.next_in_line(company, service, target_date)
    assert_equal [ matching_date, no_preference, other_date ], result.to_a
  end

  test "scope next_in_line falls back to fifo without target date" do
    company = create(:company)
    service = create(:service_type, company: company)

    first = create(:waitlist_entry, company: company, service_type: service, created_at: 3.hours.ago)
    second = create(:waitlist_entry, company: company, service_type: service, created_at: 1.hour.ago)

    result = WaitlistEntry.next_in_line(company, service)
    assert_equal [ first, second ], result.to_a
  end

  # ── Méthodes ───────────────────────────────────────────────────────────────

  test "notify! sets notified_at" do
    entry = create(:waitlist_entry)
    assert_nil entry.notified_at

    entry.notify!
    assert entry.notified_at.present?
    assert entry.notified?
  end

  test "expire! sets expired_at" do
    entry = create(:waitlist_entry)
    entry.expire!
    assert entry.expired_at.present?
    assert entry.expired?
  end

  test "pending? returns true for new entries" do
    entry = build(:waitlist_entry)
    assert entry.pending?
  end

  test "notification_expired? returns true after 24h" do
    entry = create(:waitlist_entry, notified_at: 25.hours.ago)
    assert entry.notification_expired?
  end

  test "notification_expired? returns false within 24h" do
    entry = create(:waitlist_entry, notified_at: 23.hours.ago)
    assert_not entry.notification_expired?
  end

  test "contact_email returns client_user email when present" do
    user  = build(:user, email: "user@test.com")
    entry = build(:waitlist_entry, client_user: user, client_email: "other@test.com")
    assert_equal "user@test.com", entry.contact_email
  end

  test "contact_email returns client_email for guests" do
    entry = build(:waitlist_entry, client_user: nil, client_email: "guest@test.com")
    assert_equal "guest@test.com", entry.contact_email
  end

  test "contact_name returns client_user full_name when present" do
    user  = build(:user, first_name: "Jean", last_name: "Dupont")
    entry = build(:waitlist_entry, client_user: user, client_name: "Other")
    assert_equal "Jean Dupont", entry.contact_name
  end

  test "contact_name returns client_name for guests" do
    entry = build(:waitlist_entry, client_user: nil, client_name: "Jean Guest")
    assert_equal "Jean Guest", entry.contact_name
  end

  # ── Associations ────────────────────────────────────────────────────────────

  test "belongs to company" do
    entry = build(:waitlist_entry)
    assert_respond_to entry, :company
  end

  test "belongs to service_type" do
    entry = build(:waitlist_entry)
    assert_respond_to entry, :service_type
  end

  test "belongs to client_user (optional)" do
    entry = build(:waitlist_entry, client_user: nil)
    assert entry.valid?
  end
end
