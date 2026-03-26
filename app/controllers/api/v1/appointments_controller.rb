module Api
  module V1
    class AppointmentsController < BaseController
      before_action -> { require_scope!("read:appointments") }, only: %i[index show]
      before_action -> { require_scope!("write:appointments") }, only: %i[create update destroy]
      before_action :set_appointment, only: %i[show update destroy]

      def index
        appointments = current_company.appointments
                                      .includes(:service_type, :employee, :client_user)
                                      .order(scheduled_at: :desc)

        appointments = appointments.where(status: params[:status]) if params[:status].present?
        appointments = appointments.where("scheduled_at >= ?", Time.zone.parse(params[:from])) if params[:from].present?
        appointments = appointments.where("scheduled_at <= ?", Time.zone.parse(params[:to])) if params[:to].present?

        render json: { data: Api::V1::AppointmentSerializer.render_collection(appointments) }
      end

      def show
        render json: { data: Api::V1::AppointmentSerializer.render(@appointment) }
      end

      def create
        appointment = current_company.appointments.new(appointment_params)
        appointment.booking_source ||= :manual
        appointment.duration_minutes ||= appointment.service_type&.duration_minutes

        unless service_type_allowed?(appointment.service_type_id) && employee_allowed?(appointment.employee_id)
          render json: { error: "invalid_relationship" }, status: :unprocessable_entity
          return
        end

        if appointment.save
          WebhookDispatcherService.dispatch!(
            company: current_company,
            event: "appointment.created",
            payload: { appointment_id: appointment.id, company_id: current_company.id }
          )
          render json: { data: Api::V1::AppointmentSerializer.render(appointment) }, status: :created
        else
          render_validation_errors(appointment)
        end
      end

      def update
        unless service_type_allowed?(appointment_params[:service_type_id]) && employee_allowed?(appointment_params[:employee_id])
          render json: { error: "invalid_relationship" }, status: :unprocessable_entity
          return
        end

        if @appointment.update(appointment_params)
          WebhookDispatcherService.dispatch!(
            company: current_company,
            event: "appointment.updated",
            payload: { appointment_id: @appointment.id, company_id: current_company.id }
          )
          render json: { data: Api::V1::AppointmentSerializer.render(@appointment) }
        else
          render_validation_errors(@appointment)
        end
      end

      def destroy
        if @appointment.update(status: :cancelled, cancellation_reason: params[:reason])
          WebhookDispatcherService.dispatch!(
            company: current_company,
            event: "appointment.cancelled",
            payload: { appointment_id: @appointment.id, company_id: current_company.id }
          )
          render json: { data: Api::V1::AppointmentSerializer.render(@appointment) }
        else
          render_validation_errors(@appointment)
        end
      end

      private

      def set_appointment
        @appointment = current_company.appointments.find(params[:id])
      end

      def appointment_params
        params.require(:appointment).permit(
          :service_type_id,
          :employee_id,
          :client_user_id,
          :scheduled_at,
          :duration_minutes,
          :status,
          :urgent,
          :client_notes,
          :internal_notes,
          :cancellation_reason
        )
      end

      def service_type_allowed?(service_type_id)
        return true if service_type_id.blank?

        current_company.service_types.exists?(id: service_type_id)
      end

      def employee_allowed?(employee_id)
        return true if employee_id.blank?

        current_company.employees.exists?(id: employee_id)
      end
    end
  end
end
