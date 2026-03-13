class SearchController < ApplicationController
  skip_before_action :authenticate_user!
  include Pagy::Backend

  def index
    @q = Company.active.with_public_booking.ransack(search_params)
    scope = @q.result.includes(:service_types)

    # Filtre urgent : entreprise avec un créneau dans les 24h
    if params[:urgent] == "1"
      scope = scope.available_urgently
    end

    @pagy, @companies = pagy(scope)
  end

  private

  def search_params
    params[:q]&.permit(:name_cont, :service_types_name_cont,
                        :city_cont, :service_types_price_cents_lteq)
  end
end
