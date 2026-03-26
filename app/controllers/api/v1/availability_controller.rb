module Api
  module V1
    class AvailabilityController < BaseController
      before_action -> { require_scope!("read:appointments") }

      SLOT_STEP_MINUTES = 30
      MAX_SLOTS = 200

      def index
        service_type = current_company.service_types.find(params.require(:service_type_id))
        employees = target_employees(service_type)

        start_at = parse_time(params[:start_at]) || Time.current
        end_at = parse_time(params[:end_at]) || (start_at + 7.days)
        duration = params[:duration_minutes].presence&.to_i || service_type.duration_minutes
        urgent = ActiveModel::Type::Boolean.new.cast(params[:urgent])

        slots = build_slots(employees, start_at, end_at, duration, urgent)

        render json: { data: slots }
      rescue ActionController::ParameterMissing => e
        render json: { error: "missing_parameter", message: e.message }, status: :bad_request
      end

      private

      def target_employees(service_type)
        if params[:employee_id].present?
          current_company.employees.active.where(id: params[:employee_id])
        else
          service_type.qualified_employees.active
        end
      end

      def build_slots(employees, start_at, end_at, duration, urgent)
        results = []

        employees.find_each do |employee|
          current_slot = start_at

          while current_slot <= end_at
            if employee.available_at?(current_slot, duration, urgent: urgent)
              results << {
                employee_id: employee.id,
                employee_name: employee.full_name,
                scheduled_at: current_slot.iso8601,
                ends_at: (current_slot + duration.minutes).iso8601,
                duration_minutes: duration
              }
            end

            break if results.length >= MAX_SLOTS
            current_slot += SLOT_STEP_MINUTES.minutes
          end

          break if results.length >= MAX_SLOTS
        end

        results.sort_by { |slot| slot[:scheduled_at] }
      end

      def parse_time(value)
        return nil if value.blank?

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
