# frozen_string_literal: true

class Company::BookingGroupsController < Company::BaseController
  before_action :set_booking_group, only: [ :show ]

  def index
    @pagy, @booking_groups = pagy(
      @company.booking_groups
              .includes(appointments: [ :service_type, :employee, :client_user ])
              .order(created_at: :desc)
    )
  end

  def show; end

  private

  def set_booking_group
    @booking_group = @company.booking_groups
                             .includes(appointments: [ :service_type, :employee, :client_user ])
                             .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end
end
