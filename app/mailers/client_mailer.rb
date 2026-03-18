class ClientMailer < ApplicationMailer
  # Confirmation de RDV
  def appointment_confirmed(appointment)
    @appointment = appointment
    @client      = appointment.client_user
    @company     = appointment.company
    mail(to: @client.email, subject: "Rendez-vous confirmé — #{@company.name}")
  end

  # Rappel RDV 24h avant
  def appointment_reminder(appointment)
    @appointment = appointment
    @client      = appointment.client_user
    @company     = appointment.company
    mail(to: @client.email, subject: "Rappel : votre RDV demain avec #{@company.name}")
  end

  # RDV annulé
  def appointment_cancelled(appointment)
    @appointment = appointment
    @client      = appointment.client_user
    @company     = appointment.company
    mail(to: @client.email, subject: "Rendez-vous annulé — #{@company.name}")
  end
end
