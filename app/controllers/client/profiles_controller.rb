# frozen_string_literal: true

class Client::ProfilesController < Client::BaseController
  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to client_profile_path, notice: t("profile.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :phone, :sms_opt_out, :locale)
  end
end
