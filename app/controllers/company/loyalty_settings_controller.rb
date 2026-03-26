# frozen_string_literal: true

class Company::LoyaltySettingsController < Company::BaseController
  def show
    @setting = @company.company_setting
    @total_points_awarded = @company.loyalty_points.earned.sum(:points)
    @total_codes_generated = @company.discount_codes.count
    @active_codes = @company.discount_codes.usable.count
  end

  def update
    @setting = @company.company_setting
    if @setting.update(loyalty_params)
      redirect_to company_loyalty_settings_path, notice: "Paramètres de fidélité mis à jour."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def loyalty_params
    params.require(:company_setting).permit(
      :loyalty_enabled, :points_per_appointment,
      :loyalty_points_threshold, :loyalty_discount_value_cents
    )
  end
end
