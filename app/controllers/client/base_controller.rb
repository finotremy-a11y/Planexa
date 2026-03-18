# frozen_string_literal: true

class Client::BaseController < ApplicationController
  before_action :require_client!
  layout "application"

  private

  def require_client!
    unless current_user.client?
      redirect_to root_path, alert: "Accès réservé aux clients."
    end
  end
end
