class Company::ProfilesController < Company::BaseController
  def show; end
  def edit; end
  def update
    if @company.update(company_params)
      redirect_to company_profile_path, notice: "Profil mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
  def company_params
    params.require(:company).permit(:name, :address, :city, :zip_code, :phone, :description, :website)
  end
end
