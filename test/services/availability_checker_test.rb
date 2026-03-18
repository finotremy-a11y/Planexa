require "test_helper"

class AvailabilityCheckerTest < ActiveSupport::TestCase
  setup do
    @company  = create(:company)
    @employee = create(:employee, company: @company)
    create(:schedule,
      employee:      @employee,
      company:       @company,
      day_of_week:   1,
      start_time:    "08:00",
      end_time:      "18:00",
      schedule_type: "recurring",
      available:     true)
  end

  test "disponible dans les horaires de travail" do
    checker = AvailabilityChecker.new(@employee, next_monday_at(10), 60)
    assert checker.available?
  end

  test "indisponible en dehors des horaires de travail" do
    checker = AvailabilityChecker.new(@employee, next_monday_at(20), 60)
    assert_not checker.available?
  end

  test "indisponible si un RDV est en conflit" do
    scheduled_at = next_monday_at(10)
    create(:appointment, :confirmed,
      company:         @company,
      service_type:    create(:service_type, company: @company),
      employee:        @employee,
      scheduled_at:    scheduled_at,
      duration_minutes: 60)
    checker = AvailabilityChecker.new(@employee, scheduled_at, 60)
    assert_not checker.available?
  end

  private

  def next_monday_at(hour)
    date = Date.today
    date += 1 until date.monday?
    date.to_time.change(hour: hour, min: 0, sec: 0)
  end
end
