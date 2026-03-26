# frozen_string_literal: true

# Public controller — allows client to submit a review via a secure token link
class ReviewsController < ApplicationController
  skip_before_action :authenticate_user!

  before_action :set_review
  before_action :check_expiry
  before_action :check_already_submitted

  # GET /avis/:token
  def show; end

  # POST /avis/:token
  def submit
    if @review.submit!(rating: review_params[:rating].to_i, comment: review_params[:comment])
      redirect_to submitted_reviews_path, notice: "Merci pour votre avis !"
    else
      render :show, status: :unprocessable_entity
    end
  end

  # GET /avis/merci
  def submitted; end

  private

  def set_review
    @review = Review.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Lien d'avis invalide."
  end

  def check_expiry
    if @review.expired?
      redirect_to root_path, alert: "Ce lien d'avis a expiré."
    end
  end

  def check_already_submitted
    if @review.submitted?
      redirect_to submitted_reviews_path, notice: "Vous avez déjà soumis votre avis. Merci !"
    end
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
