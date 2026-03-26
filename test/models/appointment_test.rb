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

  test "requires_payment avec acompte meme en mode paiement externe" do
    company = create(:company)
    company.setting.update!(payment_mode: :payment_external)
    service = create(:service_type, company: company, price_cents: 9000)
    service.update!(deposit_kind: :deposit_fixed_cents, deposit_value: 2500)
    appt = create(:appointment, company: company, service_type: service, client_user: create(:user, role: :client))

    assert appt.requires_payment?
    assert_equal 2500, appt.payment_amount_cents
  end

  test "payment_amount_cents retourne le total sans acompte" do
    service = create(:service_type, price_cents: 7000, deposit_kind: :deposit_none)
    appt = create(:appointment, service_type: service, company: service.company, client_user: create(:user, role: :client))

    assert_equal 7000, appt.payment_amount_cents
  end

  test "invalide si le creneau ne respecte pas l'intervalle medical" do
    company = create(:company,
      professional_category: :healthcare_professional,
      health_specialty: "Generaliste",
      convention_sector: :sector_1)
    company.setting.update!(slot_interval_minutes: 15)
    service = create(:service_type, company: company)

    appt = build(:appointment,
      company: company,
      service_type: service,
      scheduled_at: Time.zone.parse("2026-03-24 10:07"))

    assert_not appt.valid?
    assert_includes appt.errors[:scheduled_at], "doit respecter un intervalle de 15 minutes"
  end

  test "invalide si l'employe assigne n'est pas disponible" do
    company = create(:company)
    service = create(:service_type, company: company)
    employee = create(:employee, company: company)

    create(:schedule,
      company: company,
      employee: employee,
      day_of_week: 2,
      start_time: "08:00",
      end_time: "18:00",
      schedule_type: "recurring",
      available: true)

    create(:company_closure,
      company: company,
      starts_at: Time.zone.parse("2026-03-24 09:00"),
      ends_at: Time.zone.parse("2026-03-24 12:00"))

    appt = build(:appointment,
      company: company,
      service_type: service,
      employee: employee,
      scheduled_at: Time.zone.parse("2026-03-24 10:00"),
      duration_minutes: 30)

    assert_not appt.valid?
    assert_includes appt.errors[:employee_id], "n'est pas disponible sur ce creneau"
  end
end
