# frozen_string_literal: true

# Notification temps réel pour l'espace entreprise.
# Créée automatiquement lors d'événements clés (nouveau RDV, annulation, urgent).
# Broadcastée via Turbo Streams pour une mise à jour sans rechargement de page.
class Notification < ApplicationRecord
  belongs_to :company
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :kind, {
    new_booking:  0,
    cancellation: 1,
    payment:      2,
    urgent:       3
  }

  validates :kind, presence: true

  scope :unread,  -> { where(read_at: nil) }
  scope :recent,  -> { order(created_at: :desc).limit(20) }

  after_create_commit  :broadcast_notification
  after_update_commit  :broadcast_badge_update, if: -> { saved_change_to_read_at? }

  # ── Méthodes d'instance ───────────────────────────────────────────────────

  def read? = read_at.present?

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def icon
    { "new_booking" => "📅", "cancellation" => "❌",
      "payment" => "💳", "urgent" => "🚨" }.fetch(kind, "🔔")
  end

  def summary_text
    case kind
    when "new_booking"   then "Nouvelle réservation en ligne"
    when "cancellation"  then "Réservation annulée par le client"
    when "payment"       then "Paiement confirmé"
    when "urgent"        then "Rendez-vous urgent signalé"
    end
  end

  private

  def broadcast_notification
    broadcast_prepend_to(
      "company_#{company_id}_notifications",
      target:  "notifications_list",
      partial: "company/notifications/notification",
      locals:  { notification: self }
    )
    broadcast_badge_update
  end

  def broadcast_badge_update
    unread_count = company.notifications.unread.count
    broadcast_replace_to(
      "company_#{company_id}_notifications",
      target:  "notifications_badge",
      partial: "company/notifications/badge",
      locals:  { count: unread_count }
    )
  end
end
