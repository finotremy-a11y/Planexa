class ExpireWaitlistEntryJob < ApplicationJob
  queue_as :default

  # Expire une entrée de waitlist si elle n'a pas été confirmée dans les 24h
  # et notifie la personne suivante en liste d'attente
  def perform(entry_id)
    entry = WaitlistEntry.find_by(id: entry_id)

    return unless entry
    return unless entry.notified? && !entry.expired?

    # Si non confirmé dans les 24h, expirer et passer au suivant
    return unless entry.notification_expired?

    entry.expire!

    # Chercher la prochaine entrée en attente
    next_entry = WaitlistEntry.next_in_line(entry.company, entry.service_type).first
    return unless next_entry

    next_entry.notify!
    ClientMailer.waitlist_notification(next_entry, nil).deliver_now
    ExpireWaitlistEntryJob.set(wait: 24.hours).perform_later(next_entry.id)
  end
end
