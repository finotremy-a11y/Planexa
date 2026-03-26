class LocalesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_company_suspension, raise: false

  def update
    locale = params[:locale].to_s

    unless LocaleSwitcher::SUPPORTED_LOCALES.include?(locale)
      redirect_back fallback_location: root_path, alert: t("locale.unsupported")
      return
    end

    session[:locale] = locale
    current_user&.update_column(:locale, locale)

    redirect_back fallback_location: root_path, notice: t("locale.changed")
  end
end
