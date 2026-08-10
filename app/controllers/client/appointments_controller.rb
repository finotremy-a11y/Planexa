# frozen_string_literal: true

class Client::AppointmentsController < Client::BaseController
  before_action :set_appointment, only: [ :show ]
  before_action :set_cancellable_appointment, only: [ :destroy, :cancel ]

  def index
    @pagy, @appointments = pagy(
      current_user.client_appointments
                  .includes(:company, :service_type, :employee)
                  .order(scheduled_at: :desc)
    )
  end

  def show
    @conversation = Conversation.ensure_between!(
      company: @appointment.company,
      client_user: current_user
    )

    return unless @appointment.completed?

    @rebooking_url = new_appointment_path(
      company_id: @appointment.company_id,
      service_type_id: @appointment.service_type_id
    )
  end

  def destroy
    unless @appointment
      redirect_to client_appointments_path, alert: "Rendez-vous introuvable."
      return
    end

    if @appointment.pending? || @appointment.confirmed?
      @appointment.update!(status: :cancelled, cancellation_reason: "Annulé par le client")
      ClientMailer.appointment_cancelled(@appointment).deliver_later
      NotifyWaitlistJob.perform_later(@appointment.id)
      track_event("annulation", company: @appointment.company)
      redirect_to client_appointments_path, notice: "Rendez-vous annulé."
    else
      redirect_to client_appointments_path, alert: "Ce rendez-vous ne peut plus être annulé."
    end
  end

  alias_method :cancel, :destroy

  private

  def set_appointment
    @appointment = current_user.client_appointments.find(params[:id])
  end

  def set_cancellable_appointment
    @appointment = current_user.client_appointments.find_by(id: params[:id])
  end
end
