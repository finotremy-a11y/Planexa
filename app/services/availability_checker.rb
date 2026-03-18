class AvailabilityChecker
  def initialize(employee, datetime, duration_minutes)
    @employee         = employee
    @datetime         = datetime
    @duration_minutes = duration_minutes
    @end_datetime     = datetime + duration_minutes.minutes
  end

  def available?
    within_schedule? && no_conflict?
  end

  private

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
    @employee.appointments
             .where.not(status: [ :cancelled, :no_show ])
             .none? do |appt|
               appt.scheduled_at < @end_datetime &&
               appt.ends_at > @datetime
             end
  end

  def covers_timerange?(schedule, start_time, end_time)
    schedule.start_time.strftime("%H:%M") <= start_time &&
    schedule.end_time.strftime("%H:%M")   >= end_time
  end
end
