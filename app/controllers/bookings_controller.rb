# frozen_string_literal: true

class BookingsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :confirmation ]
  before_action :set_company, only: [ :new, :create ]

  # GET /reservations/nouveau?company_id=X
  # Formulaire multi-prestation (wizard : sélection N prestations → créneau → confirmation)
  def new
    @service_types = @company.service_types.active.order(:name)
    @booking_group = BookingGroup.new

    unless @company.setting.booking_public?
      redirect_to company_public_path(@company),
        alert: "Cette entreprise n'accepte pas les réservations en ligne."
    end
  end

  # POST /reservations
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
      notify_parties(bg)
      redirect_to confirmation_bookings_path(booking_group_id: bg.id)
    else
      @service_types = @company.service_types.active.order(:name)
      @booking_group = BookingGroup.new
      @errors = service.errors
      render :new, status: :unprocessable_entity
    end
  end

  # GET /reservations/confirmation?booking_group_id=X
  def confirmation
    @booking_group = BookingGroup.includes(appointments: [ :service_type, :employee ])
                                .find(params[:booking_group_id])
    @company = @booking_group.company
  end

  private

  def set_company
    @company = Company.active.find(params[:company_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to search_path, alert: "Entreprise introuvable."
  end

  def booking_params
    params.require(:booking_group).permit(:scheduled_at, :client_notes, service_type_ids: [])
  end

  def current_user_if_signed_in
    user_signed_in? ? current_user : nil
  end

  def notify_parties(booking_group)
    booking_group.appointments.each do |appointment|
      if appointment.client_user
        ClientMailer.appointment_confirmed(appointment).deliver_later
      end
      CompanyMailer.new_appointment(appointment).deliver_later
    end
  end
end
