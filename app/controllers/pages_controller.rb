# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  layout "application"

  def cgu; end
  def cgv; end
  def confidentialite; end
  def mentions_legales; end
  def contact; end

  def send_contact
    contact_params = params.permit(:name, :email, :subject, :message)

    if contact_params.values_at(:name, :email, :message).all?(&:present?)
      ContactMailer.new_message(
        contact_params[:name],
        contact_params[:email],
        contact_params[:subject],
        contact_params[:message]
      ).deliver_later

      redirect_to contact_path, notice: t("pages.contact.flash.success")
    else
      redirect_to contact_path, alert: t("pages.contact.flash.error_required")
    end
  end
end
