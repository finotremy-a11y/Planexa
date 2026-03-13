class CompaniesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @company = Company.active.find(params[:id])
    @service_types = @company.service_types.active
    @setting = @company.setting
  end
end
