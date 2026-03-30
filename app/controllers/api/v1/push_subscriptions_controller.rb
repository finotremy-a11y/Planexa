## app/controllers/api/v1/push_subscriptions_controller.rb
# API pour gérer les souscriptions aux notifications push
# Endpoints:
#   GET  /api/v1/push_subscriptions/vapid_key
#   POST /api/v1/push_subscriptions

module Api
  module V1
    class PushSubscriptionsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:create]
      before_action :authenticate_user!, except: [:vapid_key]

      # GET /api/v1/push_subscriptions/vapid_key
      # Retourne la clé publique VAPID pour les notifications push
      def vapid_key
        unless Rails.configuration.vapid[:enabled]
          render json: {
            status: "error",
            message: "Push notifications are not configured"
          }, status: :service_unavailable
          return
        end

        render json: {
          vapidPublicKey: Rails.configuration.vapid[:public_key]
        }
      end

      # POST /api/v1/push_subscriptions
      # Crée une nouvelle souscription push pour l'utilisateur courant
      def create
        user = current_user
        company = current_company
        unless company
          render json: { status: "error", message: "Company context not found" }, status: :unprocessable_entity
          return
        end

        # Extraire les données de la souscription depuis le corps JSON
        subscription_data = params.require(:subscription).permit(:endpoint, :auth, :p256dh)

        push_subscription = user.push_subscriptions.find_or_initialize_by(endpoint: subscription_data[:endpoint])
        push_subscription.assign_attributes(
          company: company,
          auth: subscription_data[:auth],
          p256dh: subscription_data[:p256dh]
        )

        if push_subscription.save
          render json: { status: 'success', message: 'Subscribed to notifications' }, status: :created
        else
          render json: { status: 'error', errors: push_subscription.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActionController::ParameterMissing => e
        render json: { status: 'error', message: "Missing parameter: #{e.message}" }, status: :bad_request
      end

      # DELETE /api/v1/push_subscriptions/:id
      # Supprime une souscription push
      def destroy
        push_subscription = current_user.push_subscriptions.find(params[:id])

        if push_subscription.destroy
          render json: { status: 'success', message: 'Unsubscribed from notifications' }, status: :ok
        else
          render json: { status: 'error', message: 'Failed to unsubscribe' }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { status: 'error', message: 'Push subscription not found' }, status: :not_found
      end

      private

      def current_company
        current_user.company || current_user.client_appointments.order(created_at: :desc).first&.company
      end
    end
  end
end
