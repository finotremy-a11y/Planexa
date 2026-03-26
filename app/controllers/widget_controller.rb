# frozen_string_literal: true

# Contrôleur du widget de réservation embarquable (iFrame / script).
# Accessible depuis n'importe quel site tiers via un token d'entreprise unique.
# Le layout `widget` supprime la navigation PlanifyPro pour une intégration propre.
class WidgetController < ApplicationController
  layout "widget"

  skip_before_action :authenticate_user!
  before_action :find_company_by_token

  # Suppression X-Frame-Options pour permettre l'intégration en iFrame sur sites tiers
  after_action :allow_iframe

  # GET /widget/:company_token
  def booking
    @service_types = @company.service_types.active.order(:name)
    @booking_group = BookingGroup.new
  end

  # POST /widget/:company_token/reservation
  def create
    service = MultiBookingService.new(
      company:          @company,
      service_type_ids: booking_params[:service_type_ids].map(&:to_i),
      scheduled_at:     Time.zone.parse(booking_params[:scheduled_at]),
      client_user:      current_user_if_signed_in,
      client_notes:     booking_params[:client_notes]
    )

    if service.call
      bg = service.booking_group
      redirect_to widget_booking_confirmation_path(
        company_token:    params[:company_token],
        booking_group_id: bg.id
      )
    else
      @service_types = @company.service_types.active.order(:name)
      @booking_group = BookingGroup.new
      @errors = service.errors
      render :booking, status: :unprocessable_entity
    end
  end

  # GET /widget/:company_token/confirmation
  def confirmation
    @booking_group = BookingGroup
      .includes(appointments: [ :service_type, :employee ])
      .find(params[:booking_group_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to widget_booking_path(company_token: params[:company_token])
  end

  private

  def find_company_by_token
    @company = Company.active.find_by!(widget_token: params[:company_token])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end

  def booking_params
    params.require(:booking_group).permit(:scheduled_at, :client_notes, service_type_ids: [])
  end

  def current_user_if_signed_in
    user_signed_in? ? current_user : nil
  end

  def allow_iframe
    response.headers.delete("X-Frame-Options")
    response.headers["Content-Security-Policy"] = "frame-ancestors *"
  end
end
