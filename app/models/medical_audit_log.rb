class MedicalAuditLog < ApplicationRecord
  belongs_to :company
  belongs_to :user, optional: true

  validates :action, :record_type, :record_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
