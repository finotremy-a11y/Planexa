require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  # — Validations —
  test "invalide sans start_time" do
    schedule = build(:schedule, start_time: nil)
    assert_not schedule.valid?
    assert schedule.errors[:start_time].any?
  end

  test "invalide sans end_time" do
    schedule = build(:schedule, end_time: nil)
    assert_not schedule.valid?
    assert schedule.errors[:end_time].any?
  end

  test "invalide si end_time <= start_time" do
    schedule = build(:schedule, start_time: "14:00", end_time: "10:00")
    assert_not schedule.valid?
    assert schedule.errors[:end_time].any?
  end

  test "invalide si end_time == start_time" do
    schedule = build(:schedule, start_time: "10:00", end_time: "10:00")
    assert_not schedule.valid?
  end

  test "invalide si recurring sans day_of_week" do
    schedule = build(:schedule, schedule_type: "recurring", day_of_week: nil)
    assert_not schedule.valid?
    assert schedule.errors[:day_of_week].any?
  end

  test "invalide si exception sans specific_date" do
    schedule = build(:schedule, schedule_type: "exception", specific_date: nil, day_of_week: nil)
    assert_not schedule.valid?
    assert schedule.errors[:specific_date].any?
  end

  test "valide récurrent avec day_of_week" do
    schedule = build(:schedule, schedule_type: "recurring", day_of_week: 1)
    assert schedule.valid?
  end

  test "valide exception avec specific_date" do
    schedule = build(:schedule, schedule_type: "exception", day_of_week: nil, specific_date: Date.tomorrow)
    assert schedule.valid?
  end

  # — Scopes —
  test "scope recurring ne retourne que les créneaux récurrents" do
    recurring  = create(:schedule, schedule_type: "recurring", day_of_week: 1)
    exception  = create(:schedule, schedule_type: "exception", day_of_week: nil, specific_date: Date.tomorrow)
    assert_includes Schedule.recurring, recurring
    assert_not_includes Schedule.recurring, exception
  end

  test "scope exceptions ne retourne que les exceptions" do
    recurring = create(:schedule, schedule_type: "recurring", day_of_week: 1)
    exception = create(:schedule, schedule_type: "exception", day_of_week: nil, specific_date: Date.tomorrow)
    assert_includes Schedule.exceptions, exception
    assert_not_includes Schedule.exceptions, recurring
  end

  test "scope for_day filtre par jour de la semaine" do
    monday  = create(:schedule, schedule_type: "recurring", day_of_week: 1)
    tuesday = create(:schedule, schedule_type: "recurring", day_of_week: 2)
    assert_includes Schedule.for_day(1), monday
    assert_not_includes Schedule.for_day(1), tuesday
  end

  test "scope for_date filtre par date spécifique" do
    today     = create(:schedule, schedule_type: "exception", day_of_week: nil, specific_date: Date.today)
    tomorrow  = create(:schedule, schedule_type: "exception", day_of_week: nil, specific_date: Date.tomorrow)
    assert_includes Schedule.for_date(Date.today), today
    assert_not_includes Schedule.for_date(Date.today), tomorrow
  end

  # — Méthodes —
  test "day_name retourne le bon nom de jour" do
    schedule = build(:schedule, day_of_week: 1)
    assert_equal "Lundi", schedule.day_name
  end

  test "day_name retourne nil sans day_of_week" do
    schedule = build(:schedule, day_of_week: nil)
    assert_nil schedule.day_name
  end
end
