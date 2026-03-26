class ApiWebhook < ApplicationRecord
  AVAILABLE_EVENTS = %w[
    appointment.created
    appointment.updated
    appointment.cancelled
    payment.succeeded
    invoice.generated
  ].freeze

  belongs_to :company

  validates :url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  validates :events, presence: true
  validates :secret, presence: true

  scope :active, -> { where(active: true) }

  before_validation :ensure_secret, on: :create
  validate :events_are_supported

  def subscribed_to?(event_name)
    events.include?(event_name.to_s)
  end

  def signature_for(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
  end

  private

  def ensure_secret
    self.secret ||= SecureRandom.hex(32)
  end

  def events_are_supported
    unsupported = Array(events).map(&:to_s) - AVAILABLE_EVENTS
    return if unsupported.empty?

    errors.add(:events, "contient des événements non supportés: #{unsupported.join(', ')}")
  end
end
