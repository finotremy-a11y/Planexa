# frozen_string_literal: true

class AppointmentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :show, :confirmation, :reconfirm ]
  before_action :set_company, only: [ :new, :create ]

  def new
    @service_types = @company.service_types.active
    @appointment   = @company.appointments.new
    @setting       = @company.setting

    @appointment.service_type_id ||= @service_types.first&.id

    prefilled_service_id = params[:service_type_id].presence
    if prefilled_service_id && @service_types.where(id: prefilled_service_id).exists?
      @appointment.service_type_id = prefilled_service_id
    end

    prefilled_scheduled_at = parse_prefilled_scheduled_at(params[:scheduled_at])
    @appointment.scheduled_at = prefilled_scheduled_at if prefilled_scheduled_at

    unless @setting.booking_public?
      redirect_to company_public_path(@company),
        alert: "Cette entreprise n'accepte pas les réservations en ligne."
    end
  end

  def create
    @appointment = @company.appointments.new(appointment_params)
    @appointment.booking_source = :online
    @appointment.client_user    = current_user if user_signed_in?

    if @company.setting.assignment_automatic?
      @appointment.employee = @company.auto_assign_employee(
        @appointment.service_type,
        @appointment.scheduled_at,
        @appointment.duration_minutes
      )
    end

    if @appointment.save
      unless @appointment.requires_payment?
        @appointment.confirmed!

        if @appointment.client_user
          ClientMailer.appointment_confirmed(@appointment).deliver_later
        end

        CompanyMailer.new_appointment(@appointment).deliver_later

        if @appointment.scheduled_at > 24.hours.from_now && @appointment.client_user
          AppointmentReminderJob
            .set(wait_until: @appointment.scheduled_at - 24.hours)
            .perform_later(@appointment.id)
        end
      end

      if @appointment.requires_payment?
        redirect_to new_appointment_payment_path(@appointment)
      else
        redirect_to confirmation_appointments_path(appointment_id: @appointment.id)
      end
    else
      @service_types = @company.service_types.active
      @setting = @company.setting
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @appointment = Appointment.includes(:company, :service_type, :client_user).find(params[:id])
  end

  def confirmation
    @appointment = Appointment.includes(:company, :service_type).find(params[:appointment_id])
  end

  def reconfirm
    appointment = Appointment.find_by(id: params[:id])
    return redirect_to root_path, alert: "Lien invalide." unless appointment

    token = params[:token].to_s
    signed_appointment = Appointment.find_signed(token, purpose: "appointment_reconfirm")

    unless signed_appointment == appointment
      return redirect_to root_path, alert: "Lien invalide ou expire."
    end

    if appointment.cancelled? || appointment.completed?
      return redirect_to appointment_path(appointment), alert: "Ce rendez-vous ne peut plus etre reconfirme."
    end

    appointment.update!(reconfirmed_at: Time.current)
    redirect_to appointment_path(appointment), notice: "Merci, votre presence est reconfirmee."
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to root_path, alert: "Lien invalide ou expire."
  end

  private

  def set_company
    @company = Company.active.find(params[:company_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to search_path, alert: "Entreprise introuvable."
  end

  def appointment_params
    params.require(:appointment).permit(
      :service_type_id, :scheduled_at, :client_notes, :urgent
    ).merge(duration_minutes: service_type_duration)
  end

  def service_type_duration
    ServiceType.find_by(id: params.dig(:appointment, :service_type_id))&.duration_minutes || 60
  end

  def parse_prefilled_scheduled_at(raw_value)
    return nil if raw_value.blank?

    Time.zone.parse(raw_value)
  rescue ArgumentError, TypeError
    nil
  end
end
