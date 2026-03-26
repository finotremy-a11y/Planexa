module Api
  module V1
    class CustomersController < BaseController
      before_action -> { require_scope!("read:customers") }

      def index
        customers = base_scope.order(:last_name, :first_name)
        customers = customers.where("users.email ILIKE ?", "%#{params[:q]}%") if params[:q].present?

        render json: { data: customers.map { |customer| Api::V1::CustomerSerializer.render(customer, company: current_company) } }
      end

      def show
        customer = base_scope.find(params[:id])
        render json: { data: Api::V1::CustomerSerializer.render(customer, company: current_company) }
      end

      private

      def base_scope
        User.joins(:client_appointments)
            .where(appointments: { company_id: current_company.id })
            .where(role: :client)
            .distinct
      end
    end
  end
end
