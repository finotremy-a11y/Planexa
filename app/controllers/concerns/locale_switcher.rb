module LocaleSwitcher
  SUPPORTED_LOCALES = %w[fr en es].freeze

  private

  def resolve_locale
    user_locale || session_locale || browser_locale || I18n.default_locale.to_s
  end

  def user_locale
    locale = current_user&.locale.to_s
    return if locale.blank?

    locale if SUPPORTED_LOCALES.include?(locale)
  end

  def session_locale
    locale = session[:locale].to_s
    return if locale.blank?

    locale if SUPPORTED_LOCALES.include?(locale)
  end

  def browser_locale
    header = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
    return if header.blank?

    locale = header.scan(/[a-z]{2}/i).first.to_s.downcase
    locale if SUPPORTED_LOCALES.include?(locale)
  end
end
