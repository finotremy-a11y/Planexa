# frozen_string_literal: true

class Admin::ReviewsController < Admin::BaseController
  before_action :set_review, only: [ :show, :destroy, :publish, :unpublish ]

  def index
    @q = Review.submitted.ransack(params[:q])
    @pagy, @reviews = pagy(
      @q.result.includes(:client_user, :company, :appointment).order(submitted_at: :desc)
    )
  end

  def show; end

  def destroy
    @review.destroy!
    redirect_to admin_reviews_path, notice: "Avis supprimé."
  end

  def publish
    @review.publish!
    redirect_to admin_review_path(@review), notice: "Avis publié."
  end

  def unpublish
    @review.unpublish!
    redirect_to admin_review_path(@review), notice: "Avis dépublié."
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end
end
