class Employee < ApplicationRecord
  belongs_to :company

  has_many :employee_skills, dependent: :destroy
  has_many :service_types, through: :employee_skills
  has_many :schedules, dependent: :destroy
  has_many :appointments, dependent: :nullify

  validates :first_name, :last_name, presence: true

  scope :active, -> { where(active: true) }
  scope :skilled_for, ->(service_type) {
    joins(:employee_skills).where(employee_skills: { service_type: service_type })
  }

  def full_name = "#{first_name} #{last_name}"

  def available_at?(datetime, duration_minutes)
    AvailabilityChecker.new(self, datetime, duration_minutes).available?
  end

  def photo_url
    return nil unless photo_public_id.present?
    Cloudinary::Utils.cloudinary_url(photo_public_id,
      width: 100, height: 100, crop: :fill, fetch_format: :auto)
  end
end
