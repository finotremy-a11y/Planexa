class ReviewRequestJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = Appointment.includes(:client_user, :company, :service_type)
                             .find_by(id: appointment_id)

    return unless appointment
    return unless appointment.completed?
    return unless appointment.client_user.present?

    # Avoid duplicate reviews
    return if Review.exists?(appointment: appointment)

    review = Review.create!(
      appointment:   appointment,
      client_user:   appointment.client_user,
      company:       appointment.company
    )

    ClientMailer.review_request(review).deliver_now
  end
end
