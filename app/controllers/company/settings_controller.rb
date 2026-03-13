class Company::SettingsController < Company::BaseController
  def show
    @setting = @company.setting
  end

  def update
    @setting = @company.setting
    if @setting.update(setting_params)
      redirect_to company_settings_path,
        notice: "Réglages sauvegardés."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:company_setting).permit(:booking_mode, :payment_mode, :assignment_mode)
  end
end
