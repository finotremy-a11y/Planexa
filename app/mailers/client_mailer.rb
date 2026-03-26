class ClientMailer < ApplicationMailer
  # Confirmation de RDV
  def appointment_confirmed(appointment)
    @appointment = appointment
    @client      = appointment.client_user
    @company     = appointment.company
    with_recipient_locale(@client) do
      mail(to: @client.email, subject: t("mailers.client.appointment_confirmed.subject", company: @company.name))
    end
  end

  # Rappel RDV 24h avant
  def appointment_reminder(appointment)
    @appointment = appointment
    @client      = appointment.client_user
    @company     = appointment.company
    token = appointment.signed_id(purpose: "appointment_reconfirm", expires_in: 7.days)
    @reconfirm_url = reconfirm_appointment_url(appointment, token: token)
    with_recipient_locale(@client) do
      mail(to: @client.email, subject: t("mailers.client.appointment_reminder.subject", company: @company.name))
    end
  end

  # RDV annulé
  def appointment_cancelled(appointment)
    @appointment = appointment
    @client      = appointment.client_user
    @company     = appointment.company
    with_recipient_locale(@client) do
      mail(to: @client.email, subject: t("mailers.client.appointment_cancelled.subject", company: @company.name))
    end
  end

  # Demande d'avis après RDV terminé
  def review_request(review)
    @review      = review
    @appointment = review.appointment
    @client      = review.client_user
    @company     = review.company
    with_recipient_locale(@client) do
      mail(
        to: @client.email,
        subject: t(
          "mailers.client.review_request.subject",
          company: @company.name,
          service: @appointment.service_type.name
        )
      )
    end
  end

  # Notification liste d'attente : un créneau s'est libéré
  def waitlist_notification(entry, appointment = nil)
    @entry       = entry
    @company     = entry.company
    @service     = entry.service_type
    @appointment = appointment
    with_recipient_locale(entry.client_user) do
      mail(
        to: entry.contact_email,
        subject: t("mailers.client.waitlist_notification.subject", company: @company.name, service: @service.name)
      )
    end
  end

  # Notification fidélité : seuil atteint, code promo généré
  def loyalty_threshold_reached(client, company)
    @client  = client
    @company = company
    @code    = client.discount_codes.where(company: company).order(created_at: :desc).first
    with_recipient_locale(@client) do
      mail(to: @client.email, subject: t("mailers.client.loyalty_threshold_reached.subject", company: @company.name))
    end
  end
end
