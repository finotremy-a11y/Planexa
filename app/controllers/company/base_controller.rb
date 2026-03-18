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
      redirect_to new_company_onboarding_path, notice: "Complétez d'abord votre profil entreprise."
    end
  end
end
