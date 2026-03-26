class NotifyWaitlistJob < ApplicationJob
  queue_as :mailers

  # Déclenché quand un RDV est annulé — notifie le premier en liste d'attente
  def perform(appointment_id)
    appointment = Appointment.includes(:company, :service_type)
                             .find_by(id: appointment_id)

    return unless appointment
    return unless appointment.cancelled?

    # Expirer les entrées notifiées depuis +24h avant de chercher
    expire_stale_notifications(appointment.company, appointment.service_type)

    # Trouver la première entrée en attente pour cette prestation
    entry = WaitlistEntry.next_in_line(
      appointment.company,
      appointment.service_type,
      appointment.scheduled_at&.to_date
    )
                         .first

    return unless entry

    entry.notify!
    ClientMailer.waitlist_notification(entry, appointment).deliver_now

    # Programmer l'expiration automatique après 24h
    ExpireWaitlistEntryJob.set(wait: 24.hours).perform_later(entry.id)
  end

  private

  def expire_stale_notifications(company, service_type)
    WaitlistEntry.where(company: company, service_type: service_type)
                 .notified
                 .where("notified_at < ?", 24.hours.ago)
                 .find_each(&:expire!)
  end
end
