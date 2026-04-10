class Company::BaseController < ApplicationController
  before_action :require_company_admin!
  before_action :set_company

  private

  def require_company_admin!
    unless current_user.company_admin?
      redirect_to root_path, alert: "Accès réservé aux entreprises."
    end
  end

  def set_company
    @company = current_user.company
    if @company.nil?
      redirect_to company_onboarding_path, notice: "Complétez d'abord votre profil entreprise."
    end
  end

  def render_not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
