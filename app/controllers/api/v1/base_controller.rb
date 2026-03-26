module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token!

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "resource_not_found" }, status: :not_found
      end

      private

      attr_reader :current_api_token, :current_company

      def authenticate_api_token!
        token_value = bearer_token
        @current_api_token = ApiToken.authenticate(token_value)

        if @current_api_token.nil? || @current_api_token.expired?
          render json: { error: "unauthorized" }, status: :unauthorized
          return
        end

        @current_company = @current_api_token.company
      end

      def require_scope!(required_scope)
        return if current_api_token.allows_scope?(required_scope)

        render json: {
          error: "forbidden",
          message: "missing_scope: #{required_scope}"
        }, status: :forbidden
      end

      def render_validation_errors(record)
        render json: {
          error: "validation_failed",
          details: record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def bearer_token
        scheme, value = request.authorization.to_s.split(" ", 2)
        return nil unless scheme&.casecmp("Bearer")&.zero?

        value
      end
    end
  end
end
