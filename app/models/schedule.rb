class Schedule < ApplicationRecord
  belongs_to :employee
  belongs_to :company

  # schedule_type: "recurring" (hebdo) ou "exception" (date précise)
  validates :start_time, :end_time, presence: true
  validate  :end_time_after_start_time
  validate  :has_day_or_date

  scope :recurring,  -> { where(schedule_type: "recurring") }
  scope :exceptions, -> { where(schedule_type: "exception") }
  scope :available,  -> { where(available: true) }
  scope :for_day, ->(day_of_week) { where(schedule_type: "recurring", day_of_week: day_of_week) }
  scope :for_date, ->(date) { where(schedule_type: "exception", specific_date: date) }

  DAY_NAMES = %w[Dimanche Lundi Mardi Mercredi Jeudi Vendredi Samedi].freeze

  def day_name
    DAY_NAMES[day_of_week] if day_of_week
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time
    errors.add(:end_time, "doit être après l'heure de début") if end_time <= start_time
  end

  def has_day_or_date
    if schedule_type == "recurring" && day_of_week.nil?
      errors.add(:day_of_week, "est requis pour un créneau récurrent")
    elsif schedule_type == "exception" && specific_date.nil?
      errors.add(:specific_date, "est requise pour une exception")
    end
  end
end
