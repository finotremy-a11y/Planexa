module Api
  module V1
    class WebhooksController < BaseController
      before_action -> { require_scope!("read:webhooks") }, only: %i[index]
      before_action -> { require_scope!("write:webhooks") }, only: %i[create destroy]
      before_action :set_webhook, only: %i[destroy]

      def index
        webhooks = current_company.api_webhooks.order(created_at: :desc)
        render json: { data: Api::V1::WebhookSerializer.render_collection(webhooks) }
      end

      def create
        webhook = current_company.api_webhooks.new(webhook_params)

        if webhook.save
          render json: { data: Api::V1::WebhookSerializer.render(webhook) }, status: :created
        else
          render_validation_errors(webhook)
        end
      end

      def destroy
        @webhook.destroy!
        render json: { success: true }
      end

      private

      def set_webhook
        @webhook = current_company.api_webhooks.find(params[:id])
      end

      def webhook_params
        params.require(:webhook).permit(:url, :active, events: [])
      end
    end
  end
end
