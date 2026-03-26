# app/services/push_notification_service.rb
# Service pour envoyer des notifications push aux utilisateurs
# Utilisé par les contrôleurs et les jobs background

class PushNotificationService
  # Envoyer une notification push à un utilisateur spécifique
  # @param user [User] L'utilisateur destinataire
  # @param title [String] Titre de la notification
  # @param body [String] Corps de la notification
  # @param data [Hash] Données supplémentaires à transmettre
  def self.notify_user(user:, title:, body:, data: {})
    company_id = data[:company_id]
    
    subscriptions = if company_id
                      user.push_subscriptions.where(company_id: company_id)
                    else
                      user.push_subscriptions
                    end

    subscriptions.each do |subscription|
      subscription.send_notification(
        title: title,
        body: body,
        data: data
      )
    end
  end

  # Envoyer une notification push à tous les users d'une compagnie
  # @param company [Company]
  # @param users [Array<User>]
  # @param title [String]
  # @param body [String]
  # @param data [Hash]
  def self.notify_company_users(company:, users:, title:, body:, data: {})
    users.each do |user|
      notify_user(user: user, title: title, body: body, data: data.merge(company_id: company.id))
    end
  end

  # Envoyer une notification pour un nouveau RDV créé
  # @param appointment [Appointment]
  def self.notify_new_appointment(appointment)
    title = "Nouveau rendez-vous"
    body = "#{appointment.service_type.name} avec #{appointment.company.name}"
    data = {
      url: "/appointments/#{appointment.id}",
      company_id: appointment.company_id,
      type: 'appointment.created'
    }

    # Notifier tous les utilisateurs connectés à cette compagnie
    # (propriétaire + employés-utilisateurs)
    company_users = [ appointment.company.user ].compact
    if company_users.any?
      notify_company_users(
        company: appointment.company,
        users: company_users,
        title: title,
        body: body,
        data: data
      )
    end

    # Optionnel: notifier aussi le client si app installée
    if appointment.client_user&.push_subscriptions&.any?
      notify_user(
        user: appointment.client_user,
        title: "Confirmation RDV",
        body: "Votre RDV du #{appointment.scheduled_at.strftime('%d/%m à %H:%M')} est confirmé",
        data: data
      )
    end
  end

  # Envoyer une notification de rappel avant un RDV
  # @param appointment [Appointment]
  def self.notify_appointment_reminder(appointment)
    title = "Rappel RDV"
    body = "#{appointment.service_type.name} dans #{time_until_appointment(appointment)}"
    data = {
      url: "/appointments/#{appointment.id}",
      company_id: appointment.company_id,
      type: 'appointment.reminder'
    }

    # Notifier le client
    if appointment.client_user&.push_subscriptions&.any?
      notify_user(
        user: appointment.client_user,
        title: title,
        body: body,
        data: data
      )
    end

    # Notifier aussi les employés
    if appointment.employee&.user&.push_subscriptions&.any?
      notify_user(
        user: appointment.employee.user,
        title: title,
        body: body,
        data: data
      )
    end
  end

  # Envoyer une notification pour un RDV annulé
  # @param appointment [Appointment]
  def self.notify_appointment_cancelled(appointment)
    title = "RDV Annulé"
    body = "Votre RDV du #{appointment.scheduled_at.strftime('%d/%m à %H:%M')} a été annulé"
    data = {
      url: "/appointments",
      company_id: appointment.company_id,
      type: 'appointment.cancelled'
    }

    if appointment.client_user&.push_subscriptions&.any?
      notify_user(
        user: appointment.client_user,
        title: title,
        body: body,
        data: data
      )
    end
  end

  # Envoyer une notification pour un paiement reçu
  # @param payment [Payment]
  def self.notify_payment_received(payment)
    title = "Paiement reçu"
    body = "#{number_to_currency(payment.amount)} reçu"
    data = {
      url: "/invoices/#{payment.invoice_id}",
      company_id: payment.company_id,
      type: 'payment.received'
    }

    if payment.user&.push_subscriptions&.any?
      notify_user(
        user: payment.user,
        title: title,
        body: body,
        data: data
      )
    end
  end

  # Envoyer une notification pour une facture générée
  # @param invoice [Invoice]
  def self.notify_invoice_generated(invoice)
    title = "Facture générée"
    body = "#{invoice.invoice_number} - #{number_to_currency(invoice.total)}"
    data = {
      url: "/invoices/#{invoice.id}",
      company_id: invoice.company_id,
      type: 'invoice.generated'
    }

    invoice_users = [ invoice.company.user ].compact
    if invoice_users.any?
      notify_company_users(
        company: invoice.company,
        users: invoice_users,
        title: title,
        body: body,
        data: data
      )
    end
  end

  # Envoyer une notification de test
  # @param user [User]
  def self.send_test_notification(user:)
    notify_user(
      user: user,
      title: "Notification de test",
      body: "Les notifications push fonctionnent correctement ! ✨",
      data: { type: 'test' }
    )
  end

  private

  def self.time_until_appointment(appointment)
    minutes = ((appointment.scheduled_at - Time.current) / 60).to_i
    hours = minutes / 60
    remaining_minutes = minutes % 60

    if hours > 0
      "#{hours}h #{remaining_minutes}min"
    else
      "#{remaining_minutes}min"
    end
  end

  def self.number_to_currency(amount)
    ActionController::Base.helpers.number_to_currency(amount / 100.0, unit: '€', locale: :fr)
  end
end
