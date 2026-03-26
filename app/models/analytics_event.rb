# frozen_string_literal: true

class AnalyticsEvent < ApplicationRecord
  belongs_to :company, optional: true
  belongs_to :user,    optional: true

  validates :name, presence: true

  # Shorthand writer used by the Trackable concern
  def self.record(name, company: nil, user: nil, session_id: nil, **properties)
    create!(
      name:       name,
      company_id: company&.id,
      user_id:    user&.id,
      session_id: session_id,
      properties: properties
    )
  rescue ActiveRecord::RecordInvalid
    # Never let tracking failures affect the user flow
    Rails.logger.warn("[AnalyticsEvent] Failed to record event: #{name}")
  end

  # Funnel query helpers used by the statistics controller
  def self.funnel_for(company, period: 30)
    since = period.days.ago
    where(company_id: company.id, created_at: since..)
      .group(:name)
      .count
  end
end
