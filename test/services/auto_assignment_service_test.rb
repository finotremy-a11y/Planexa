require "test_helper"

class AutoAssignmentServiceTest < ActiveSupport::TestCase
  setup do
    @company  = create(:company)
    @service  = create(:service_type, company: @company)
    @employee = create(:employee, company: @company)
    create(:employee_skill, employee: @employee, service_type: @service)
    create(:schedule,
      employee:      @employee,
      company:       @company,
      day_of_week:   1,
      start_time:    "08:00",
      end_time:      "18:00",
      schedule_type: "recurring",
      available:     true)
  end

  test "retourne un employé qualifié et disponible" do
    scheduled_at = next_monday_at(10)
    service      = AutoAssignmentService.new(@company, @service, scheduled_at, 60)
    assert_equal @employee, service.call
  end

  test "retourne nil si l'employé a déjà un RDV sur ce créneau" do
    scheduled_at = next_monday_at(10)
    create(:appointment, :confirmed,
      company:         @company,
      service_type:    @service,
      employee:        @employee,
      scheduled_at:    scheduled_at,
      duration_minutes: 60)
    service = AutoAssignmentService.new(@company, @service, scheduled_at, 60)
    assert_nil service.call
  end

  test "retourne nil si l'employé n'a pas la compétence requise" do
    other_service = create(:service_type, company: @company)
    scheduled_at  = next_monday_at(10)
    service       = AutoAssignmentService.new(@company, other_service, scheduled_at, 60)
    assert_nil service.call
  end

  private

  def next_monday_at(hour)
    date = Date.today
    date += 1 until date.monday?
    date.to_time.change(hour: hour, min: 0, sec: 0)
  end
end
