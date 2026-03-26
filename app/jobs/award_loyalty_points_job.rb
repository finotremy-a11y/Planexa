# frozen_string_literal: true

class AwardLoyaltyPointsJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find_by(id: appointment_id)
    return unless appointment&.completed?

    LoyaltyService.new(appointment).award_points!
  end
end
