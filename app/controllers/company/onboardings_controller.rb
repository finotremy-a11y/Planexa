class Company::OnboardingsController < ApplicationController
  before_action :require_company_admin!
  before_action :redirect_if_company_exists, only: [ :show, :update ]

  def show
    @company = current_user.build_company
  end

  def update
    @company = current_user.build_company(company_params)

    if @company.save
      redirect_to company_root_path, notice: "Profil entreprise créé."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def require_company_admin!
    redirect_to root_path, alert: "Accès réservé aux entreprises." unless current_user&.company_admin?
  end

  def redirect_if_company_exists
    redirect_to company_root_path if current_user.company.present?
  end

  def company_params
    params.require(:company).permit(
      :name, :siret, :address, :city, :zip_code,
      :phone, :description, :website,
      :professional_category, :health_specialty,
      :convention_sector, :teleconsultation_enabled,
      :accessibility_info, :practical_info, :cancellation_policy
    )
  end
end