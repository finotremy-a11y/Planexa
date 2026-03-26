# frozen_string_literal: true

class EmployeeAbsence < ApplicationRecord
  belongs_to :employee

  REASONS = %w[vacation sick training other].freeze

  validates :starts_at, :ends_at, presence: true
  validates :reason, inclusion: { in: REASONS }
  validate  :ends_after_starts

  scope :active,      -> { where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current) }
  scope :upcoming,    -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :past,        -> { where("ends_at < ?", Time.current).order(ends_at: :desc) }
  scope :covering,    ->(from, to) {
    where("starts_at < ? AND ends_at > ?", to, from)
  }

  def reason_label
    I18n.t("employee_absence.reasons.#{reason}", default: reason.humanize)
  end

  def duration_days
    ((ends_at - starts_at) / 1.day).ceil
  end

  private

  def ends_after_starts
    return unless starts_at && ends_at
    errors.add(:ends_at, "doit être après la date de début") if ends_at <= starts_at
  end
end
