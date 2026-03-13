class CompanySetting < ApplicationRecord
  belongs_to :company

  enum :booking_mode,    { booking_public: 0, booking_private: 1 }
  enum :payment_mode,    { payment_in_app: 0, payment_external: 1 }
  enum :assignment_mode, { assignment_automatic: 0, assignment_manual: 1 }

  validates :booking_mode, :payment_mode, :assignment_mode, presence: true

  def public_booking? = booking_mode == "booking_public"
  def in_app_payment? = payment_mode == "payment_in_app"
  def auto_assignment? = assignment_mode == "assignment_automatic"
end
