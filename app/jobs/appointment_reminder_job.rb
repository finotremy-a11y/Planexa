class AppointmentReminderJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = Appointment.includes(:client_user, :company, :service_type).find_by(id: appointment_id)
    return unless appointment
    return if appointment.cancelled? || appointment.completed?

    sent_channels = 0
    sent_channels += 1 if send_email_reminder(appointment) == :sent
    sent_channels += 1 if send_sms_reminder(appointment) == :sent
    sent_channels += 1 if send_push_reminder(appointment) == :sent

    appointment.mark_reconfirmation_requested! if sent_channels.positive?
  end

  private

  def send_email_reminder(appointment)
    return log_skipped(appointment, :email, "client_absent") unless appointment.client_user
    return log_skipped(appointment, :email, "channel_disabled") unless appointment.company.setting.email_reminders_enabled?

    ClientMailer.appointment_reminder(appointment).deliver_now
    log_sent(appointment, :email)
  rescue StandardError => e
    log_failed(appointment, :email, e.message)
  end

  def send_sms_reminder(appointment)
    client = appointment.client_user
    return log_skipped(appointment, :sms, "client_absent") unless client
    return log_skipped(appointment, :sms, "channel_disabled") unless appointment.company.setting.sms_reminders_enabled?
    return log_skipped(appointment, :sms, "sms_opt_out") if client.sms_opt_out?
    return log_skipped(appointment, :sms, "phone_missing") unless client.phone.present?

    service_name = appointment.service_type.name
    date_str     = appointment.scheduled_at.strftime("%d/%m/%Y à %Hh%M")
    company_name = appointment.company.name
    reconfirm_url = reconfirm_url_for(appointment)

    body = "Rappel RDV : #{service_name} chez #{company_name} le #{date_str}. Confirmer: #{reconfirm_url}"

    if SmsService.send(to: client.phone, body: body)
      log_sent(appointment, :sms)
    else
      log_failed(appointment, :sms, "sms_send_failed")
    end
  rescue StandardError => e
    log_failed(appointment, :sms, e.message)
  end

  def send_push_reminder(appointment)
    client = appointment.client_user
    return log_skipped(appointment, :push, "client_absent") unless client
    return log_skipped(appointment, :push, "channel_disabled") unless appointment.company.setting.push_reminders_enabled?

    subscriptions = client.push_subscriptions.where(company: appointment.company)
    return log_skipped(appointment, :push, "no_subscription") if subscriptions.empty?

    title = "Rappel RDV"
    body = "#{appointment.service_type.name} chez #{appointment.company.name} demain a #{appointment.scheduled_at.strftime('%Hh%M')}"
    reconfirm_url = reconfirm_url_for(appointment)
    data = {
      type: "appointment.reminder",
      appointment_id: appointment.id,
      company_id: appointment.company_id,
      scheduled_at: appointment.scheduled_at.iso8601,
      reconfirm_url: reconfirm_url
    }

    subscriptions.each do |subscription|
      subscription.send_notification(title: title, body: body, data: data)
    end
    log_sent(appointment, :push)
  rescue StandardError => e
    log_failed(appointment, :push, e.message)
  end

  def log_sent(appointment, channel)
    ReminderDelivery.create!(
      company: appointment.company,
      appointment: appointment,
      channel: channel,
      status: :sent,
      delivered_at: Time.current
    )

    :sent
  end

  def log_skipped(appointment, channel, reason)
    ReminderDelivery.create!(
      company: appointment.company,
      appointment: appointment,
      channel: channel,
      status: :skipped,
      error_message: reason
    )

    :skipped
  end

  def log_failed(appointment, channel, message)
    ReminderDelivery.create!(
      company: appointment.company,
      appointment: appointment,
      channel: channel,
      status: :failed,
      error_message: message.to_s.first(500)
    )

    :failed
  end

  def reconfirm_url_for(appointment)
    token = appointment.signed_id(purpose: "appointment_reconfirm", expires_in: 7.days)
    Rails.application.routes.url_helpers.reconfirm_appointment_path(appointment, token: token)
  end
end
