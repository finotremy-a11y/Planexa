require "test_helper"

class NotifyWaitlistJobTest < ActiveSupport::TestCase
  test "notifies first pending waitlist entry on cancellation" do
    company = create(:company)
    service = create(:service_type, company: company)
    appointment = create(:appointment, company: company, service_type: service, status: :cancelled)

    entry = create(:waitlist_entry, company: company, service_type: service)

    ClientMailer.expects(:waitlist_notification).with(entry, appointment).returns(mock(deliver_now: true))
    ExpireWaitlistEntryJob.expects(:set).with(wait: 24.hours).returns(mock(perform_later: true))

    NotifyWaitlistJob.perform_now(appointment.id)

    entry.reload
    assert entry.notified?
  end

  test "does nothing if no pending waitlist entries" do
    appointment = create(:appointment, status: :cancelled)
    ClientMailer.expects(:waitlist_notification).never

    NotifyWaitlistJob.perform_now(appointment.id)
  end

  test "does nothing if appointment not cancelled" do
    appointment = create(:appointment, status: :confirmed)
    ClientMailer.expects(:waitlist_notification).never

    NotifyWaitlistJob.perform_now(appointment.id)
  end

  test "does nothing if appointment not found" do
    ClientMailer.expects(:waitlist_notification).never
    NotifyWaitlistJob.perform_now(-1)
  end

  test "skips already notified entries" do
    company = create(:company)
    service = create(:service_type, company: company)
    appointment = create(:appointment, company: company, service_type: service, status: :cancelled)

    _notified = create(:waitlist_entry, :notified, company: company, service_type: service)
    pending_entry = create(:waitlist_entry, company: company, service_type: service)

    ClientMailer.expects(:waitlist_notification).with(pending_entry, appointment).returns(mock(deliver_now: true))
    ExpireWaitlistEntryJob.expects(:set).with(wait: 24.hours).returns(mock(perform_later: true))

    NotifyWaitlistJob.perform_now(appointment.id)

    pending_entry.reload
    assert pending_entry.notified?
  end

  test "expires stale notifications before finding next entry" do
    company = create(:company)
    service = create(:service_type, company: company)
    appointment = create(:appointment, company: company, service_type: service, status: :cancelled)

    stale = create(:waitlist_entry, company: company, service_type: service, notified_at: 25.hours.ago)
    fresh = create(:waitlist_entry, company: company, service_type: service)

    ClientMailer.expects(:waitlist_notification).with(fresh, appointment).returns(mock(deliver_now: true))
    ExpireWaitlistEntryJob.expects(:set).with(wait: 24.hours).returns(mock(perform_later: true))

    NotifyWaitlistJob.perform_now(appointment.id)

    stale.reload
    assert stale.expired?
    fresh.reload
    assert fresh.notified?
  end

  test "prioritizes entry with matching preferred date" do
    company = create(:company)
    service = create(:service_type, company: company)
    target_date = 4.days.from_now.to_date
    appointment = create(:appointment, company: company, service_type: service,
                                       status: :cancelled,
                                       scheduled_at: target_date.noon)

    _older_different_date = create(:waitlist_entry, company: company, service_type: service,
                                                    preferred_date: target_date + 1.day,
                                                    created_at: 2.days.ago)
    matching_date = create(:waitlist_entry, company: company, service_type: service,
                                            preferred_date: target_date,
                                            created_at: 1.day.ago)

    ClientMailer.expects(:waitlist_notification).with(matching_date, appointment).returns(mock(deliver_now: true))
    ExpireWaitlistEntryJob.expects(:set).with(wait: 24.hours).returns(mock(perform_later: true))

    NotifyWaitlistJob.perform_now(appointment.id)

    matching_date.reload
    assert matching_date.notified?
  end
end
