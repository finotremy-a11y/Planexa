require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  # — Validations —
  test "invalid without scheduled_at" do
    appt = build(:appointment, scheduled_at: nil)
    assert_not appt.valid?
    assert appt.errors[:scheduled_at].any?
  end

  test "invalid without duration_minutes" do
    appt = build(:appointment, duration_minutes: nil)
    assert_not appt.valid?
    assert appt.errors[:duration_minutes].any?
  end

  test "invalid if duration_minutes is zero" do
    appt = build(:appointment, duration_minutes: 0)
    assert_not appt.valid?
  end

  # — Methods —
  test "ends_at retourne l'heure de fin correcte" do
    appointment = build(:appointment, scheduled_at: Time.zone.parse("2025-01-01 10:00"), duration_minutes: 60)
    assert_equal Time.zone.parse("2025-01-01 11:00"), appointment.ends_at
  end

  # — Scopes —
  test "scope upcoming ne retourne que les futurs RDV" do
    past_appt   = create(:appointment, scheduled_at: 1.day.ago)
    future_appt = create(:appointment, scheduled_at: 1.day.from_now)
    assert_includes Appointment.upcoming, future_appt
    assert_not_includes Appointment.upcoming, past_appt
  end

  test "scope today ne retourne que les RDV du jour" do
    today_appt = create(:appointment, scheduled_at: Time.current.change(hour: 14))
    other_appt = create(:appointment, scheduled_at: 2.days.from_now)
    assert_includes Appointment.today, today_appt
    assert_not_includes Appointment.today, other_appt
  end
end
