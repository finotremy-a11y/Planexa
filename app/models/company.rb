class Company < ApplicationRecord
  # ── Associations ───────────────────────────────────────────────────────────
  belongs_to :user

  has_one  :company_setting, dependent: :destroy
  has_one  :subscription,    dependent: :destroy
  has_many :employees,        dependent: :destroy
  has_many :service_types,    dependent: :destroy
  has_many :appointments,     dependent: :destroy
  has_many :schedules,        dependent: :destroy
  has_many :payments,         dependent: :destroy

  has_many :employee_skills, through: :employees
  has_many :skilled_service_types, through: :employee_skills, source: :service_type

  # ── Enums ──────────────────────────────────────────────────────────────────
  enum :status, { active: 0, suspended: 1, pending: 2 }

  # ── Validations ────────────────────────────────────────────────────────────
  validates :name,     presence: true
  validates :siret,    presence: true, uniqueness: true,
                      format: { with: /\A\d{14}\z/, message: "doit contenir 14 chiffres" }
  validates :address, :city, :zip_code, presence: true

  # ── Callbacks ──────────────────────────────────────────────────────────────
  after_create :create_default_setting

  # ── Scopes ─────────────────────────────────────────────────────────────────
  scope :with_public_booking, -> {
    joins(:company_setting).where(company_settings: { booking_mode: 0 })
  }

  scope :available_urgently, -> {
    joins(:schedules).where(
      "schedules.specific_date = ? OR schedules.day_of_week = ?",
      Date.today, Date.today.wday
    ).where(schedules: { available: true }).distinct
  }

  # ── Méthodes ───────────────────────────────────────────────────────────────
  def setting
    company_setting || create_company_setting
  end

  def subscription_active?
    subscription&.active? || subscription&.trialing?
  end

  def trial_active?
    subscription&.trialing? && subscription.trial_ends_at&.future?
  end

  def logo_url
    return nil unless logo_public_id.present?
    Cloudinary::Utils.cloudinary_url(logo_public_id,
      width: 200, height: 200, crop: :fill, fetch_format: :auto)
  end

  # Service pour l'assignation automatique d'employé
  def auto_assign_employee(service_type, scheduled_at, duration_minutes)
    AutoAssignmentService.new(self, service_type, scheduled_at, duration_minutes).call
  end

  private

  def create_default_setting
    create_company_setting(
      booking_mode:    :booking_public,
      payment_mode:    :payment_external,
      assignment_mode: :assignment_automatic
    )
  end
end
