class Appointment < ApplicationRecord
  belongs_to :company
  belongs_to :service_type
  belongs_to :client_user, class_name: "User",     optional: true
  belongs_to :employee,                             optional: true
  belongs_to :booking_group,                        optional: true
  has_one    :payment, dependent: :destroy
  has_one    :review,  dependent: :destroy
  has_many   :loyalty_points, dependent: :nullify
  has_many   :reminder_deliveries, dependent: :destroy

  enum :status, {
    pending:    0,
    confirmed:  1,
    cancelled:  2,
    completed:  3,
    no_show:    4
  }

  enum :booking_source, { online: 0, manual: 1 }

  validates :scheduled_at, :duration_minutes, presence: true
  validates :duration_minutes, numericality: { greater_than: 0 }
  validate :scheduled_at_respects_slot_interval, if: :healthcare_company?
  validate :employee_is_available_when_assigned, if: :employee_assigned?

  scope :upcoming,  -> { where("scheduled_at > ?", Time.current).order(:scheduled_at) }
  scope :past,      -> { where("scheduled_at <= ?", Time.current).order(scheduled_at: :desc) }
  scope :today,     -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :urgent,    -> { where(urgent: true) }
  scope :unassigned, -> { where(employee_id: nil) }

  def ends_at
    scheduled_at + duration_minutes.minutes
  end

  def requires_payment?
    return false unless client_user.present?

    service_type.deposit_required? || company.setting.in_app_payment?
  end

  def payment_amount_cents
    return service_type.deposit_amount_cents if service_type.deposit_required?

    service_type.price_cents
  end

  def paid?
    payment&.succeeded?
  end

  def reconfirmation_requested?
    reconfirmation_requested_at.present?
  end

  def reconfirmed?
    reconfirmed_at.present?
  end

  def reconfirmation_pending?
    reconfirmation_requested? && !reconfirmed?
  end

  def mark_reconfirmation_requested!
    return if reconfirmation_requested?

    update!(reconfirmation_requested_at: Time.current)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[status scheduled_at urgent employee_id client_user_id service_type_id company_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company service_type client_user employee]
  end

  # ── Notifications temps réel ──────────────────────────────────────────────
  after_create_commit  :notify_new_booking,   if: :online?
  after_update_commit  :notify_cancellation,  if: :just_cancelled?
  after_update_commit  :notify_urgent_flag,   if: :just_flagged_urgent?

  private

  def notify_new_booking
    Notification.create!(company: company, notifiable: self, kind: :new_booking)
  end

  def notify_cancellation
    Notification.create!(company: company, notifiable: self, kind: :cancellation)
  end

  def notify_urgent_flag
    Notification.create!(company: company, notifiable: self, kind: :urgent)
  end

  def just_cancelled?
    saved_change_to_status? && cancelled?
  end

  def just_flagged_urgent?
    saved_change_to_urgent? && urgent?
  end

  def healthcare_company?
    company&.healthcare_professional?
  end

  def employee_assigned?
    employee.present? && scheduled_at.present? && duration_minutes.present?
  end

  def scheduled_at_respects_slot_interval
    interval = company.setting.slot_interval_minutes.to_i
    return if interval <= 0

    if (scheduled_at.min % interval).nonzero?
      errors.add(:scheduled_at, "doit respecter un intervalle de #{interval} minutes")
    end
  end

  def employee_is_available_when_assigned
    checker = AvailabilityChecker.new(employee, scheduled_at, duration_minutes, urgent: urgent?)
    return if checker.available?(exclude_appointment_id: id)

    errors.add(:employee_id, "n'est pas disponible sur ce creneau")
  end
end
