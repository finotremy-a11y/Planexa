class Appointment < ApplicationRecord
  belongs_to :company
  belongs_to :service_type
  belongs_to :client_user, class_name: "User",     optional: true
  belongs_to :employee,                             optional: true
  has_one    :payment, dependent: :destroy

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

  scope :upcoming,  -> { where("scheduled_at > ?", Time.current).order(:scheduled_at) }
  scope :past,      -> { where("scheduled_at <= ?", Time.current).order(scheduled_at: :desc) }
  scope :today,     -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :urgent,    -> { where(urgent: true) }
  scope :unassigned, -> { where(employee_id: nil) }

  def ends_at
    scheduled_at + duration_minutes.minutes
  end

  def requires_payment?
    company.setting.in_app_payment? && client_user.present?
  end

  def paid?
    payment&.succeeded?
  end
end
