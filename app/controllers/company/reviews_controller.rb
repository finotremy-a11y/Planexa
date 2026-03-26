# frozen_string_literal: true

class Company::ReviewsController < Company::BaseController
  before_action :set_review, only: [ :show, :destroy ]

  def index
    @q = policy_scope(Review).where(company: @company)
                              .submitted
                              .ransack(params[:q])
    @pagy, @reviews = pagy(
      @q.result.includes(:client_user, :appointment).order(submitted_at: :desc)
    )
  end

  def show
    authorize @review
  end

  def destroy
    authorize @review
    @review.destroy!
    redirect_to company_reviews_path, notice: "Avis supprimé."
  end

  private

  def set_review
    @review = @company.reviews.find(params[:id])
  end
end
