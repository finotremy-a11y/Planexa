class AppointmentReminderJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = Appointment.includes(:client_user, :company, :service_type).find_by(id: appointment_id)
    return unless appointment
    return if appointment.cancelled? || appointment.completed?

    ClientMailer.appointment_reminder(appointment).deliver_now
  end
end
