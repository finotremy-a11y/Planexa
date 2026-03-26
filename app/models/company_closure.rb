class CompanyClosure < ApplicationRecord
  belongs_to :company

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_starts

  scope :upcoming, -> { where("ends_at >= ?", Time.current).order(:starts_at) }
  scope :covering, ->(from, to) {
    where("starts_at < ? AND ends_at > ?", to, from)
  }

  private

  def ends_after_starts
    return unless starts_at && ends_at

    errors.add(:ends_at, "doit etre apres la date de debut") if ends_at <= starts_at
  end
end