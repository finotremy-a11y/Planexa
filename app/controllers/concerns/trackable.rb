# frozen_string_literal: true

# Concern included in ApplicationController.
# Provides a fire-and-forget track_event helper that never raises.
module Trackable
  extend ActiveSupport::Concern

  private

  def track_event(name, company: nil, **props)
    AnalyticsEvent.record(
      name,
      company:    company,
      user:       (current_user if user_signed_in?),
      session_id: session.id.to_s.presence,
      **props
    )
  rescue StandardError
    # Silently ignore — analytics must never break real flows
  end
end
