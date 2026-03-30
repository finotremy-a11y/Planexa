class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Planexa <noreply@planexa.fr>")
  layout "mailer"

  private

  def with_recipient_locale(user, &block)
    locale = user&.locale.presence || I18n.default_locale
    I18n.with_locale(locale, &block)
  end
end
