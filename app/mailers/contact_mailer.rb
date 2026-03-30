# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  def new_message(name, email, subject, message)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: ENV.fetch("EMAIL_CONTACT", "contact@planexa.fr"),
      from: ENV.fetch("MAIL_FROM", "Planexa <noreply@planexa.fr>"),
      reply_to: email,
      subject: t("mailers.contact.new_message.subject", subject: subject.presence || t("mailers.contact.new_message.default_subject"))
    )
  end
end
