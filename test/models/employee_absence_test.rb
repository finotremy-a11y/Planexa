# frozen_string_literal: true

require "test_helper"

class EmployeeAbsenceTest < ActiveSupport::TestCase
  # ── Validations ────────────────────────────────────────────────────────────
  test "valide avec attributs corrects" do
    absence = build(:employee_absence)
    assert absence.valid?
  end

  test "invalide sans starts_at" do
    absence = build(:employee_absence, starts_at: nil)
    assert_not absence.valid?
    assert absence.errors[:starts_at].any?
  end

  test "invalide sans ends_at" do
    absence = build(:employee_absence, ends_at: nil)
    assert_not absence.valid?
    assert absence.errors[:ends_at].any?
  end

  test "invalide si ends_at avant starts_at" do
    absence = build(:employee_absence,
      starts_at: 2.days.from_now,
      ends_at:   1.day.from_now
    )
    assert_not absence.valid?
    assert absence.errors[:ends_at].any?
  end

  test "invalide si ends_at égal starts_at" do
    now = Time.current
    absence = build(:employee_absence, starts_at: now, ends_at: now)
    assert_not absence.valid?
    assert absence.errors[:ends_at].any?
  end

  test "invalide avec reason inconnue" do
    absence = build(:employee_absence, reason: "party")
    assert_not absence.valid?
    assert absence.errors[:reason].any?
  end

  test "valide avec chaque reason autorisée" do
    %w[vacation sick training other].each do |reason|
      absence = build(:employee_absence, reason: reason)
      assert absence.valid?, "Devrait être valide avec reason=#{reason}"
    end
  end

  # ── Associations ───────────────────────────────────────────────────────────
  test "appartient à un employee" do
    absence = create(:employee_absence)
    assert_not_nil absence.employee
  end

  # ── Scopes ─────────────────────────────────────────────────────────────────
  test "scope active retourne les absences en cours" do
    employee = create(:employee)
    active   = create(:employee_absence, :active_now, employee: employee)
    future   = create(:employee_absence, employee: employee)
    past     = create(:employee_absence, :past, employee: employee)

    result = EmployeeAbsence.active
    assert_includes result, active
    assert_not_includes result, future
    assert_not_includes result, past
  end

  test "scope upcoming retourne les absences futures" do
    employee = create(:employee)
    future   = create(:employee_absence, employee: employee,
                      starts_at: 5.days.from_now, ends_at: 7.days.from_now)
    past     = create(:employee_absence, :past, employee: employee)

    result = EmployeeAbsence.upcoming
    assert_includes result, future
    assert_not_includes result, past
  end

  test "scope past retourne les absences passées" do
    employee = create(:employee)
    past     = create(:employee_absence, :past, employee: employee)
    future   = create(:employee_absence, employee: employee,
                      starts_at: 5.days.from_now, ends_at: 7.days.from_now)

    result = EmployeeAbsence.past
    assert_includes result, past
    assert_not_includes result, future
  end

  test "scope covering retourne les absences couvrant un créneau" do
    employee = create(:employee)
    absence  = create(:employee_absence, employee: employee,
                      starts_at: 1.day.ago, ends_at: 3.days.from_now)
    outside  = create(:employee_absence, employee: employee,
                      starts_at: 10.days.from_now, ends_at: 12.days.from_now)

    from = Time.current
    to   = 1.hour.from_now

    result = EmployeeAbsence.covering(from, to)
    assert_includes result, absence
    assert_not_includes result, outside
  end

  # ── Méthodes ───────────────────────────────────────────────────────────────
  test "reason_label retourne un libellé traduit" do
    absence = build(:employee_absence, reason: "vacation")
    label = absence.reason_label
    assert_kind_of String, label
    assert label.present?
  end

  test "duration_days calcule correctement la durée" do
    start = Time.current.beginning_of_day
    absence = build(:employee_absence,
      starts_at: start,
      ends_at:   start + 3.days
    )
    assert_equal 3, absence.duration_days
  end

  test "duration_days arrondit au jour supérieur" do
    start = Time.current.beginning_of_day
    absence = build(:employee_absence,
      starts_at: start,
      ends_at:   start + 1.5.days
    )
    assert_equal 2, absence.duration_days
  end
end
