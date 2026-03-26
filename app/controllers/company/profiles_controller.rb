class Company::ProfilesController < Company::BaseController
  def show; end
  def edit; end
  def update
    if @company.update(company_params)
      MedicalAuditLogger.log!(
        company: @company,
        user: current_user,
        action: "medical_profile_updated",
        record: @company,
        metadata: {
          changed_fields: @company.saved_changes.keys & %w[
            professional_category
            health_specialty
            convention_sector
            teleconsultation_enabled
            accessibility_info
            practical_info
            cancellation_policy
          ]
        }
      )
      redirect_to company_profile_path, notice: "Profil mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
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
