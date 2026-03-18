class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Planify Pro <noreply@planifypro.fr>")
  layout "mailer"
end
