require "test_helper"

class ExpireWaitlistEntryJobTest < ActiveSupport::TestCase
  test "expires entry after 24h and notifies next in line" do
    company = create(:company)
    service = create(:service_type, company: company)

    expired_entry = create(:waitlist_entry, company: company, service_type: service, notified_at: 25.hours.ago)
    next_entry = create(:waitlist_entry, company: company, service_type: service)

    ClientMailer.expects(:waitlist_notification).with(next_entry, nil).returns(mock(deliver_now: true))
    ExpireWaitlistEntryJob.expects(:set).with(wait: 24.hours).returns(mock(perform_later: true))

    ExpireWaitlistEntryJob.perform_now(expired_entry.id)

    expired_entry.reload
    assert expired_entry.expired?
    next_entry.reload
    assert next_entry.notified?
  end

  test "does nothing if entry does not exist" do
    ClientMailer.expects(:waitlist_notification).never
    ExpireWaitlistEntryJob.perform_now(-1)
  end

  test "does nothing if entry not yet expired (within 24h)" do
    entry = create(:waitlist_entry, notified_at: 23.hours.ago)
    ExpireWaitlistEntryJob.perform_now(entry.id)

    entry.reload
    assert_not entry.expired?
  end

  test "does nothing if entry already expired" do
    entry = create(:waitlist_entry, :expired, notified_at: 25.hours.ago)
    ClientMailer.expects(:waitlist_notification).never
    ExpireWaitlistEntryJob.perform_now(entry.id)
  end

  test "expires without notifying next if no pending entries" do
    entry = create(:waitlist_entry, notified_at: 25.hours.ago)
    ClientMailer.expects(:waitlist_notification).never

    ExpireWaitlistEntryJob.perform_now(entry.id)

    entry.reload
    assert entry.expired?
  end
end
