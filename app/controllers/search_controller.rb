class SearchController < ApplicationController
  skip_before_action :authenticate_user!
  include Pagy::Backend

  def index
    scope = Company.active.with_public_booking.includes(:service_types, :company_setting)

    if params[:name].present?
      scope = scope.where("companies.name ILIKE ?", "%#{params[:name]}%")
    end

    if params[:activity].present?
      scope = scope.joins(:service_types)
                   .where("service_types.name ILIKE ?", "%#{params[:activity]}%")
                   .distinct
    end

    if params[:max_price].present?
      scope = scope.joins(:service_types)
                   .where("service_types.price_cents <= ?", params[:max_price].to_i * 100)
                   .distinct
    end

    if params[:urgent] == "1"
      scope = scope.available_urgently
    end

    if params[:city].present?
      scope = scope.where("city ILIKE ?", "%#{params[:city]}%")
    end

    @pagy, @companies = pagy(scope)
    @search_params = params.permit(:name, :activity, :max_price, :urgent, :city)
  end
end
