class WaitlistEntry < ApplicationRecord
  # ── Associations ───────────────────────────────────────────────────────────
  belongs_to :company
  belongs_to :service_type
  belongs_to :client_user, class_name: "User", optional: true

  # ── Validations ────────────────────────────────────────────────────────────
  validates :token, presence: true, uniqueness: true
  validates :client_email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            unless: :client_user
  validates :client_name, presence: true, unless: :client_user

  validate :client_user_or_contact_info

  # ── Callbacks ──────────────────────────────────────────────────────────────
  before_validation :generate_token, on: :create
  before_validation :populate_from_user, on: :create

  # ── Scopes ─────────────────────────────────────────────────────────────────
  scope :pending,  -> { where(notified_at: nil, expired_at: nil) }
  scope :notified, -> { where.not(notified_at: nil).where(expired_at: nil) }
  scope :expired,  -> { where.not(expired_at: nil) }
  scope :active,   -> { where(expired_at: nil) }

  scope :for_service, ->(service_type) { where(service_type: service_type) }
  scope :for_date,    ->(date) { where(preferred_date: date) }

  scope :next_in_line, ->(company, service_type, target_date = nil) {
    relation = where(company: company, service_type: service_type).pending

    if target_date.present?
      # Priority rule: same preferred_date first, then no preference, then other dates; FIFO in each group.
      priority_sql = sanitize_sql_array([
        "CASE WHEN preferred_date = ? THEN 0 WHEN preferred_date IS NULL THEN 1 ELSE 2 END",
        target_date
      ])
      relation.order(Arel.sql(priority_sql)).order(:created_at)
    else
      relation.order(:created_at)
    end
  }

  # ── Méthodes ───────────────────────────────────────────────────────────────

  def notify!
    update!(notified_at: Time.current)
  end

  def expire!
    update!(expired_at: Time.current)
  end

  def notified?
    notified_at.present?
  end

  def expired?
    expired_at.present?
  end

  def pending?
    !notified? && !expired?
  end

  def contact_email
    client_user&.email || client_email
  end

  def contact_name
    client_user&.full_name || client_name
  end

  # Expiration auto : 24h après notification pour confirmer
  def notification_expired?
    notified? && notified_at < 24.hours.ago
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[client_email client_name preferred_date notified_at expired_at created_at
       company_id service_type_id client_user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company service_type client_user]
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32) if token.blank?
  end

  def populate_from_user
    return unless client_user

    self.client_email ||= client_user.email
    self.client_name  ||= client_user.full_name
  end

  def client_user_or_contact_info
    return if client_user.present?
    return if client_email.present? && client_name.present?

    errors.add(:base, "Un utilisateur connecté ou un email et nom sont requis")
  end
end
