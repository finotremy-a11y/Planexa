# frozen_string_literal: true

# Service responsable de la création d'un groupe de réservation multi-prestation.
# Crée un BookingGroup + N Appointment en une seule transaction, avec vérification
# de la disponibilité globale (créneaux séquentiels sur un même employé).
class MultiBookingService
  attr_reader :booking_group, :errors

  def initialize(company:, service_type_ids:, scheduled_at:, client_user: nil, client_notes: nil)
    @company          = company
    @service_type_ids = service_type_ids
    @scheduled_at     = scheduled_at
    @client_user      = client_user
    @client_notes     = client_notes
    @errors           = []
  end

  def call
    return add_error("Sélectionnez au moins 2 prestations") if @service_type_ids.size < 2

    @service_types = @company.service_types.active.where(id: @service_type_ids)
    return add_error("Prestations introuvables") if @service_types.size != @service_type_ids.size

    employee = find_available_employee
    return add_error("Aucun employé disponible pour ce créneau combiné") unless employee

    ActiveRecord::Base.transaction do
      create_booking_group!
      create_appointments!(employee)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  private

  def ordered_service_types
    @ordered_service_types ||= @service_type_ids.map { |id| @service_types.find { |st| st.id == id } }
  end

  def total_duration
    @total_duration ||= ordered_service_types.sum(&:duration_minutes)
  end

  def total_amount_cents
    ordered_service_types.sum(&:price_cents)
  end

  def find_available_employee
    candidates = @company.employees.active

    # Chercher un employé compétent pour TOUTES les prestations via sous-requêtes
    # (le chaînage de joins sur la même table génère un SQL impossible)
    @service_types.each do |st|
      candidates = candidates.where(id: EmployeeSkill.where(service_type: st).select(:employee_id))
    end

    # Vérifier la disponibilité sur la durée totale combinée
    candidates.find do |employee|
      AvailabilityChecker.new(employee, @scheduled_at, total_duration).available?
    end
  end

  def create_booking_group!
    @booking_group = BookingGroup.create!(
      company:            @company,
      client_user:        @client_user,
      total_amount_cents: total_amount_cents,
      status:             :pending,
      client_notes:       @client_notes
    )
  end

  def create_appointments!(employee)
    current_time = @scheduled_at

    ordered_service_types.each do |service_type|
      @booking_group.appointments.create!(
        company:          @company,
        service_type:     service_type,
        client_user:      @client_user,
        employee:         employee,
        scheduled_at:     current_time,
        duration_minutes: service_type.duration_minutes,
        booking_source:   :online,
        status:           :pending
      )
      current_time += service_type.duration_minutes.minutes
    end
  end

  def add_error(message)
    @errors << message
    false
  end
end
