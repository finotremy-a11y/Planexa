class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :check_company_suspension, if: :company_admin_signed_in?

  # Pundit — redirection en cas d'accès non autorisé
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Pagy
  include Pagy::Backend

  private

  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
    redirect_back(fallback_location: root_path)
  end

  def check_company_suspension
    return unless current_user.company_admin?
    return unless current_user.company&.suspended?
    return if request.path.start_with?("/company/abonnement", "/users/sign_out")

    redirect_to company_subscription_path,
      alert: "Votre compte est suspendu. Veuillez régulariser votre abonnement."
  end

  def company_admin_signed_in?
    user_signed_in? && current_user.company_admin?
  end

  def after_sign_in_path_for(resource)
    case resource.role
    when "admin"         then admin_root_path
    when "company_admin" then company_root_path
    else                      client_root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
