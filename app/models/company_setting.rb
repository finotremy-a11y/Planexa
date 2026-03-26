class CompanySetting < ApplicationRecord
  belongs_to :company

  enum :booking_mode,    { booking_public: 0, booking_private: 1 }
  enum :payment_mode,    { payment_in_app: 0, payment_external: 1 }
  enum :assignment_mode, { assignment_automatic: 0, assignment_manual: 1 }

  validates :booking_mode, :payment_mode, :assignment_mode, presence: true
  validates :slot_interval_minutes,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 60 }
  validates :buffer_between_appointments_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 120 }
  validates :overbooking_limit_per_slot,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }
  validates :emergency_daily_capacity,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 50 }

  def public_booking?  = booking_mode == "booking_public"
  def in_app_payment?  = payment_mode == "payment_in_app"
  def auto_assignment? = assignment_mode == "assignment_automatic"
  def email_reminders_enabled? = email_reminders_enabled == true
  def sms_reminders_enabled? = sms_reminders_enabled == true
  def push_reminders_enabled? = push_reminders_enabled == true
  def loyalty_enabled? = loyalty_enabled == true
  def allow_controlled_overbooking? = allow_controlled_overbooking == true
end
