# frozen_string_literal: true

class Admin::BaseController < ApplicationController
  before_action :require_admin!
  layout "admin"

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Accès non autorisé."
    end
  end
end
