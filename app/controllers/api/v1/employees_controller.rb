module Api
  module V1
    class EmployeesController < BaseController
      before_action -> { require_scope!("read:employees") }

      def index
        employees = current_company.employees.includes(:service_types).order(:last_name, :first_name)
        employees = employees.where(active: params[:active]) if params[:active].present?

        render json: { data: Api::V1::EmployeeSerializer.render_collection(employees) }
      end
    end
  end
end
