class ServiceType < ApplicationRecord
  belongs_to :company

  has_many :employee_skills, dependent: :destroy
  has_many :employees, through: :employee_skills
  has_many :appointments, dependent: :restrict_with_error
  has_many :waitlist_entries, dependent: :destroy

  monetize :price_cents, with_currency: :eur

  enum :deposit_kind, {
    deposit_none: 0,
    deposit_fixed_cents: 1,
    deposit_percentage: 2
  }

  validates :name,             presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :price_cents,      numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_value,    numericality: { greater_than_or_equal_to: 0 }
  validate :deposit_configuration_is_valid

  scope :active, -> { where(active: true) }

  def qualified_employees
    employees.joins(:employee_skills)
             .where(employee_skills: { service_type: self })
             .where(active: true)
  end

  def deposit_required?
    !deposit_none? && deposit_amount_cents.positive?
  end

  def deposit_amount_cents
    case deposit_kind
    when "deposit_fixed_cents"
      [ deposit_value, price_cents ].min
    when "deposit_percentage"
      [ ((price_cents * deposit_value) / 100.0).round, price_cents ].min
    else
      0
    end
  end

  private

  def deposit_configuration_is_valid
    return if deposit_none?

    if deposit_fixed_cents?
      errors.add(:deposit_value, "doit etre superieur a 0") if deposit_value <= 0
      errors.add(:deposit_value, "ne peut pas depasser le prix") if deposit_value > price_cents
    end

    return unless deposit_percentage?

    errors.add(:deposit_value, "doit etre entre 1 et 100") unless deposit_value.between?(1, 100)
  end
end
