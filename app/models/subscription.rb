class Subscription < ApplicationRecord
  belongs_to :company

  enum :status, {
    trialing:  0,
    active:    1,
    past_due:  2,
    canceled:  3,
    suspended: 4
  }

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_price_id,        presence: true

  scope :overdue, -> { where(status: :past_due).where("current_period_end < ?", Time.current) }
  scope :trial_ending_soon, -> {
    where(status: :trialing).where(trial_ends_at: ..3.days.from_now)
  }

  def days_until_trial_ends
    return 0 unless trial_ends_at
    [(trial_ends_at - Time.current) / 1.day, 0].max.ceil
  end

  def suspend!
    update!(status: :suspended, suspended_at: Time.current)
    company.suspended!
  end

  def reactivate!
    update!(status: :active, suspended_at: nil)
    company.active!
  end
end
