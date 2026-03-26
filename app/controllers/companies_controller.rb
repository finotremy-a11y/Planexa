class CompaniesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @company = Company.active.find(params[:id])
    @service_types = @company.service_types.active
    @setting = @company.setting
    @priority_slot = @setting.booking_public? ? @company.next_available_slot : nil
    @reviews = @company.reviews.published.includes(:client_user, :appointment).recent.limit(10)
    @avg_rating = Review.average_rating_for(@company)
    @review_count = Review.count_for(@company)

    track_event("fiche_viewed", company: @company)
  end
end
