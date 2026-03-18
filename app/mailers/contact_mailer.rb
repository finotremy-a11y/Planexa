# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  def new_message(name, email, subject, message)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: ENV.fetch("EMAIL_CONTACT", "contact@planifypro.fr"),
      from: ENV.fetch("MAIL_FROM", "Planify Pro <noreply@planifypro.fr>"),
      reply_to: email,
      subject: "[Contact Planify Pro] #{subject.presence || 'Nouveau message'}"
    )
  end
end
