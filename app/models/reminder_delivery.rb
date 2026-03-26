class ReminderDelivery < ApplicationRecord
  belongs_to :company
  belongs_to :appointment

  enum :channel, { email: 0, sms: 1, push: 2 }
  enum :status, { sent: 0, skipped: 1, failed: 2 }

  validates :channel, :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
