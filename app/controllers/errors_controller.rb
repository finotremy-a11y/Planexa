# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!

  def not_found
    render "errors/not_found", status: :not_found, layout: false
  end

  def internal_server_error
    render "errors/internal_server_error", status: :internal_server_error, layout: false
  end
end
