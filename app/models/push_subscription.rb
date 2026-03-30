## app/models/push_subscription.rb
# Modèle pour gérer les abonnements aux notifications push
# Stocke les endpoints push et les clés d'authentification VAPID

class PushSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :company

  validates :endpoint, presence: true, uniqueness: { scope: [:user_id, :company_id] }
  validates :auth, presence: true
  validates :p256dh, presence: true
  validates :user_id, presence: true
  validates :company_id, presence: true

  # Envoyer une notification push à cet utilisateur
  def send_notification(title:, body:, icon: nil, tag: 'planify-pro', data: {})
    unless Rails.configuration.vapid[:enabled]
      Rails.logger.info("Push notifications are disabled: missing VAPID configuration")
      return
    end

    WebPush.payload_send(
      endpoint: endpoint,
      message: {
        title: title,
        body: body,
        icon: icon || '/icons/icon-192x192.png',
        badge: '/icons/icon-192x192.png',
        tag: tag,
        data: data
      }.to_json,
      p256dh: p256dh,
      auth: auth,
      vapid: {
        subject: Rails.configuration.vapid[:subject],
        public_key: Rails.configuration.vapid[:public_key],
        private_key: Rails.configuration.vapid[:private_key]
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription => e
    # L'abonnement est expiré ou invalide, le supprimer
    destroy
    Rails.logger.warn("Push subscription removed: #{e.message}")
  rescue => e
    Rails.logger.error("Failed to send push notification: #{e.message}")
  end

  # Scope: abonnements actifs pour une compagnie
  scope :for_company, ->(company) { where(company_id: company.id) }
  scope :for_user, ->(user) { where(user_id: user.id) }

  # Scope: abonnements créés récemment
  scope :recent, -> { order(created_at: :desc) }
end
