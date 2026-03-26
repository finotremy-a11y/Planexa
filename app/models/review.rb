class Review < ApplicationRecord
  belongs_to :appointment
  belongs_to :client_user, class_name: "User"
  belongs_to :company

  # ── Validations ────────────────────────────────────────────────────────────
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :rating,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 },
    allow_nil: true

  validate :rating_required_when_submitted, if: :submitted_at?

  # ── Scopes ─────────────────────────────────────────────────────────────────
  scope :published,   -> { where.not(published_at: nil) }
  scope :submitted,   -> { where.not(submitted_at: nil) }
  scope :pending,     -> { where(submitted_at: nil) }
  scope :expired,     -> { where("expires_at < ?", Time.current).where(submitted_at: nil) }
  scope :by_rating,   -> { order(rating: :desc) }
  scope :recent,      -> { order(published_at: :desc) }

  # ── Callbacks ──────────────────────────────────────────────────────────────
  before_validation :generate_token, on: :create
  before_validation :set_expiry,     on: :create

  # ── Methods ────────────────────────────────────────────────────────────────
  def submitted?    = submitted_at.present?
  def published?    = published_at.present?
  def expired?      = !submitted? && expires_at < Time.current
  def pending?      = !submitted?

  def submit!(rating:, comment: nil)
    update!(
      rating:       rating,
      comment:      comment,
      submitted_at: Time.current,
      published_at: Time.current
    )
  end

  def publish!
    update!(published_at: Time.current)
  end

  def unpublish!
    update!(published_at: nil)
  end

  def self.average_rating_for(company)
    published.where(company: company).average(:rating)&.round(1)
  end

  def self.count_for(company)
    published.where(company: company).count
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[rating submitted_at published_at company_id client_user_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company client_user appointment]
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at ||= 30.days.from_now
  end

  def rating_required_when_submitted
    errors.add(:rating, "est obligatoire pour soumettre un avis") if rating.blank?
  end
end
