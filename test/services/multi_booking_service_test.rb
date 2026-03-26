# frozen_string_literal: true

require "test_helper"

class MultiBookingServiceTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @company.setting.update!(booking_mode: :booking_public)

    @service1 = create(:service_type, company: @company, duration_minutes: 30, price_cents: 2000, active: true)
    @service2 = create(:service_type, company: @company, duration_minutes: 45, price_cents: 3000, active: true)

    @employee = create(:employee, company: @company, active: true)
    # Compétences sur les deux prestations
    @employee.employee_skills.create!(service_type: @service1)
    @employee.employee_skills.create!(service_type: @service2)
    # Horaire toute la semaine 08:00-20:00
    (0..6).each do |day|
      @employee.schedules.create!(company: @company, day_of_week: day, start_time: "08:00", end_time: "20:00",
                                  available: true, schedule_type: :recurring)
    end

    @client      = create(:user, role: :client)
    @scheduled_at = 2.days.from_now.change(hour: 10, min: 0, sec: 0)
  end

  # ── Cas nominal ─────────────────────────────────────────────────────────

  test "call crée un BookingGroup et N appointments" do
    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, @service2.id ],
      scheduled_at:     @scheduled_at,
      client_user:      @client
    )

    result = nil
    assert_difference "BookingGroup.count", 1 do
      assert_difference "Appointment.count", 2 do
        result = service.call
      end
    end
    assert result, service.errors.inspect

    bg = service.booking_group
    assert_equal @company, bg.company
    assert_equal @client, bg.client_user
    assert_equal 5000, bg.total_amount_cents
    assert_equal "pending", bg.status
    assert_equal 2, bg.appointments.count
  end

  test "les appointments sont ordonnés séquentiellement" do
    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, @service2.id ],
      scheduled_at:     @scheduled_at,
      client_user:      @client
    )
    service.call

    appts = service.booking_group.appointments.order(:scheduled_at)
    assert_equal @scheduled_at, appts.first.scheduled_at
    # Deuxième commence après la durée du premier
    assert_equal @scheduled_at + 30.minutes, appts.last.scheduled_at
  end

  test "call sans client_user fonctionne (réservation anonyme)" do
    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, @service2.id ],
      scheduled_at:     @scheduled_at,
      client_user:      nil
    )
    assert service.call, service.errors.inspect
    assert_nil service.booking_group.client_user
  end

  # ── Règles métier ────────────────────────────────────────────────────────

  test "call échoue si moins de 2 prestations" do
    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id ],
      scheduled_at:     @scheduled_at
    )
    assert_not service.call
    assert_includes service.errors, "Sélectionnez au moins 2 prestations"
  end

  test "call échoue si une prestation est introuvable" do
    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, 0 ],
      scheduled_at:     @scheduled_at
    )
    assert_not service.call
    assert_includes service.errors, "Prestations introuvables"
  end

  test "call échoue si aucun employé disponible" do
    # Bloquer l'employé sur le créneau
    @employee.appointments.create!(
      company:          @company,
      service_type:     @service1,
      scheduled_at:     @scheduled_at,
      duration_minutes: 120,
      status:           :confirmed,
      booking_source:   :online
    )

    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, @service2.id ],
      scheduled_at:     @scheduled_at
    )
    assert_not service.call
    assert_includes service.errors, "Aucun employé disponible pour ce créneau combiné"
  end

  test "call échoue si l'employé n'a pas les compétences pour toutes les prestations" do
    service3 = create(:service_type, company: @company, active: true)
    # service3 sans compétence sur l'employé

    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, service3.id ],
      scheduled_at:     @scheduled_at
    )
    assert_not service.call
    assert_includes service.errors, "Aucun employé disponible pour ce créneau combiné"
  end

  # ── Intégrité transactionnelle ───────────────────────────────────────────

  test "aucun enregistrement créé en cas d'erreur transactionnelle" do
    # Corrompre le service_type_id pour provoquer une RecordInvalid dans la transaction
    @service1.update_column(:active, false)

    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, @service2.id ],
      scheduled_at:     @scheduled_at
    )

    assert_no_difference [ "BookingGroup.count", "Appointment.count" ] do
      service.call
    end
  end

  # ── Montant total ────────────────────────────────────────────────────────

  test "total_amount_cents est la somme des prestations" do
    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: [ @service1.id, @service2.id ],
      scheduled_at:     @scheduled_at
    )
    service.call
    assert_equal @service1.price_cents + @service2.price_cents, service.booking_group.total_amount_cents
  end
end
