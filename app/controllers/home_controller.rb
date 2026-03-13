class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @companies_count = Company.active.count
    @featured_companies = Company.active
                                  .with_public_booking
                                  .includes(:service_types)
                                  .limit(6)
  end
end
