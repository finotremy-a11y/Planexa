# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :destroy ]

  def index
    @q = User.ransack(params[:q])
    @pagy, @users = pagy(
      @q.result.order(created_at: :desc)
    )
  end

  def show; end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "Vous ne pouvez pas supprimer votre propre compte."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "Utilisateur supprimé."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
