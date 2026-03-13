class ServiceType < ApplicationRecord
  belongs_to :company

  has_many :employee_skills, dependent: :destroy
  has_many :employees, through: :employee_skills
  has_many :appointments, dependent: :restrict_with_error

  monetize :price_cents, with_currency: :eur

  validates :name,             presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :price_cents,      numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }

  def qualified_employees
    employees.joins(:employee_skills)
             .where(employee_skills: { service_type: self })
             .where(active: true)
  end
end
