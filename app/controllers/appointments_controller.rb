# frozen_string_literal: true

class AppointmentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :show, :confirmation ]
  before_action :set_company, only: [ :new, :create ]

  def new
    @service_types = @company.service_types.active
    @appointment   = @company.appointments.new
    @setting       = @company.setting

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
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @appointment = Appointment.includes(:company, :service_type, :client_user).find(params[:id])
  end

  def confirmation
    @appointment = Appointment.includes(:company, :service_type).find(params[:appointment_id])
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
end
