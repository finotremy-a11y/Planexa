class AvailabilityChecker
  def initialize(employee, datetime, duration_minutes, urgent: false)
    @employee         = employee
    @company          = employee.company
    @setting          = @company.setting
    @datetime         = datetime
    @duration_minutes = duration_minutes
    @urgent           = urgent
    @end_datetime     = datetime + duration_minutes.minutes
    @buffer_minutes   = @setting.buffer_between_appointments_minutes.to_i
  end

  def available?(exclude_appointment_id: nil)
    @exclude_appointment_id = exclude_appointment_id
    within_schedule? && no_conflict? && not_absent? && not_company_closed?
  end

  private

  # Vérifie que l'employé n'est pas en absence sur le créneau demandé
  def not_absent?
    @employee.employee_absences
             .covering(@datetime, @end_datetime)
             .none?
  end

  def not_company_closed?
    @company.company_closures.covering(@datetime, @end_datetime).none?
  end

  # Vérifie si le créneau est dans les horaires de l'employé
  def within_schedule?
    date       = @datetime.to_date
    day_of_w   = @datetime.wday
    start_time = @datetime.strftime("%H:%M")
    end_time   = @end_datetime.strftime("%H:%M")

    # Chercher une exception pour ce jour précis
    exception = @employee.schedules
                         .exceptions
                         .for_date(date)
                         .first

    if exception
      return false unless exception.available?
      return covers_timerange?(exception, start_time, end_time)
    end

    # Sinon, chercher le créneau récurrent pour ce jour de la semaine
    recurring = @employee.schedules
                         .recurring
                         .for_day(day_of_w)
                         .available
                         .first

    return false unless recurring
    covers_timerange?(recurring, start_time, end_time)
  end

  # Vérifie qu'il n'y a pas de chevauchement avec un autre RDV
  def no_conflict?
    overlap_count = overlapping_appointments.count
    return true if overlap_count.zero?

    overlap_count <= allowed_overbooking_limit
  end

  def overlapping_appointments
    relation = @employee.appointments
                        .where.not(status: [ :cancelled, :no_show ])
    relation = relation.where.not(id: @exclude_appointment_id) if @exclude_appointment_id.present?

    relation.select do |appt|
      appointment_end_with_buffer = appt.ends_at + @buffer_minutes.minutes
      requested_end_with_buffer = @end_datetime + @buffer_minutes.minutes

      appt.scheduled_at < requested_end_with_buffer &&
        appointment_end_with_buffer > @datetime
    end
  end

  def allowed_overbooking_limit
    base_limit = @setting.allow_controlled_overbooking? ? @setting.overbooking_limit_per_slot.to_i : 0
    return base_limit unless @urgent
    return base_limit unless emergency_capacity_available?

    [ base_limit, 1 ].max
  end

  def emergency_capacity_available?
    day_range = @datetime.beginning_of_day..@datetime.end_of_day
    scope = @company.appointments.urgent.where(scheduled_at: day_range).where.not(status: [ :cancelled, :no_show ])
    scope = scope.where.not(id: @exclude_appointment_id) if @exclude_appointment_id.present?

    scope.count < @setting.emergency_daily_capacity.to_i
  end

  def covers_timerange?(schedule, start_time, end_time)
    schedule.start_time.strftime("%H:%M") <= start_time &&
    schedule.end_time.strftime("%H:%M")   >= end_time
  end
end
