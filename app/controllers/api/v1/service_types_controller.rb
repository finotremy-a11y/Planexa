module Api
  module V1
    class ServiceTypesController < BaseController
      before_action -> { require_scope!("read:service_types") }

      def index
        service_types = current_company.service_types.order(:name)
        service_types = service_types.where(active: params[:active]) if params[:active].present?

        render json: { data: Api::V1::ServiceTypeSerializer.render_collection(service_types) }
      end
    end
  end
end
