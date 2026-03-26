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
  has_many :reviews,           dependent: :destroy
  has_many :waitlist_entries,  dependent: :destroy
  has_many :loyalty_points,    dependent: :destroy
  has_many :discount_codes,    dependent: :destroy
  has_many :booking_groups,    dependent: :destroy
  has_many :notifications,     dependent: :destroy
  has_many :invoices,           dependent: :destroy
  has_many :reminder_deliveries, dependent: :destroy
  has_many :api_tokens,        dependent: :destroy
  has_many :api_webhooks,      dependent: :destroy
  has_many :company_closures,  dependent: :destroy
  has_many :medical_audit_logs, dependent: :destroy

  has_many :employee_skills, through: :employees
  has_many :skilled_service_types, through: :employee_skills, source: :service_type

  # ── Enums ──────────────────────────────────────────────────────────────────
  enum :status, { active: 0, suspended: 1, pending: 2 }
  enum :professional_category, {
    standard_business: 0,
    healthcare_professional: 1
  }

  enum :convention_sector, {
    not_conventioned: "not_conventioned",
    sector_1: "sector_1",
    sector_2: "sector_2"
  }, prefix: :convention

  # ── Validations ────────────────────────────────────────────────────────────
  validates :name,     presence: true
  validates :siret,    presence: true, uniqueness: true,
                      format: { with: /\A\d{14}\z/, message: "doit contenir 14 chiffres" }
  validates :address, :city, :zip_code, presence: true
  validates :widget_token, presence: true, uniqueness: true
  validates :health_specialty, presence: true, if: :healthcare_professional?
  validates :convention_sector, presence: true, if: :healthcare_professional?

  # ── Callbacks ──────────────────────────────────────────────────────────────
  before_validation :generate_widget_token, on: :create
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

  def onboarding_checklist_items
    healthcare_details_complete = !healthcare_professional? || [ health_specialty, convention_sector ].all?(&:present?)
    profile_complete = [ name, address, city, zip_code, phone ].all?(&:present?) && healthcare_details_complete
    schedules_complete = schedules.available.exists?
    services_complete = service_types.active.exists?
    public_page_complete = setting.public_booking?
    payment_required = setting.in_app_payment?
    payment_complete = !payment_required || stripe_onboarding_complete?

    [
      {
        key: :profile,
        completed: profile_complete,
        path: :company_profile_path,
        required: true
      },
      {
        key: :schedules,
        completed: schedules_complete,
        path: :company_schedules_path,
        required: true
      },
      {
        key: :services,
        completed: services_complete,
        path: :company_service_types_path,
        required: true
      },
      {
        key: :public_page,
        completed: public_page_complete,
        path: :company_settings_path,
        required: true
      },
      {
        key: :payment,
        completed: payment_complete,
        path: :company_settings_path,
        required: payment_required
      }
    ]
  end

  def onboarding_completion_percentage
    total_items = onboarding_checklist_items.count
    return 0 if total_items.zero?

    completed_items = onboarding_checklist_items.count { |item| item[:completed] }
    ((completed_items.to_f / total_items) * 100).round
  end

  def onboarding_blockers
    onboarding_checklist_items.select { |item| item[:required] && !item[:completed] }
  end

  def ready_to_receive_bookings?
    onboarding_blockers.empty?
  end

  def trial_active?
    subscription&.trialing? && subscription.trial_ends_at&.future?
  end

  def logo_url
    return nil unless logo_public_id.present?
    Cloudinary::Utils.cloudinary_url(logo_public_id,
      width: 200, height: 200, crop: :fill, fetch_format: :auto)
  end

  # Returns the first near-term slot for a qualified employee.
  # We cap the search window to keep this usable on a public page.
  def next_available_slot(service_type: nil, start_at: Time.current, step_minutes: 30, max_checks: 96)
    target_service = service_type || service_types.active.order(:id).first
    return nil unless target_service

    qualified_employees = target_service.qualified_employees.active
    return nil if qualified_employees.empty?

    candidate = align_to_slot(start_at, step_minutes)

    max_checks.times do
      qualified_employees.each do |employee|
        if employee.available_at?(candidate, target_service.duration_minutes)
          return {
            scheduled_at: candidate,
            service_type: target_service,
            employee: employee
          }
        end
      end

      candidate += step_minutes.minutes
    end

    nil
  end

  # Service pour l'assignation automatique d'employé
  def auto_assign_employee(service_type, scheduled_at, duration_minutes)
    AutoAssignmentService.new(self, service_type, scheduled_at, duration_minutes).call
  end

  # Génère un nouveau token de widget (invalide l'ancien)
  def regenerate_widget_token!
    update!(widget_token: SecureRandom.uuid)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[city created_at name siret status updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[subscription user]
  end

  private

  def align_to_slot(datetime, step_minutes)
    aligned = datetime.change(sec: 0)
    minute_remainder = aligned.min % step_minutes
    return aligned if minute_remainder.zero?

    aligned + (step_minutes - minute_remainder).minutes
  end

  def generate_widget_token
    self.widget_token = SecureRandom.uuid if widget_token.blank?
  end

  def create_default_setting
    create_company_setting(
      booking_mode:    :booking_public,
      payment_mode:    :payment_external,
      assignment_mode: :assignment_automatic
    )
  end
end
