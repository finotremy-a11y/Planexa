# frozen_string_literal: true

class Admin::SubscriptionsController < Admin::BaseController
  before_action :set_subscription, only: [ :show, :cancel ]

  def index
    @q = Subscription.includes(:company).ransack(params[:q])
    @pagy, @subscriptions = pagy(
      @q.result.order(created_at: :desc)
    )

    # Compteurs par statut
    @counts = {
      active: Subscription.active.count,
      trialing: Subscription.trialing.count,
      past_due: Subscription.past_due.count,
      suspended: Subscription.suspended.count,
      canceled: Subscription.canceled.count
    }
  end

  def show
    @company = @subscription.company
  end

  def cancel
    ::Stripe::Subscription.cancel(@subscription.stripe_subscription_id)
    @subscription.update!(status: :canceled)
    @subscription.company.suspended!
    redirect_to admin_subscription_path(@subscription),
      notice: "Abonnement annulé."
  rescue ::Stripe::StripeError => e
    redirect_to admin_subscription_path(@subscription),
      alert: "Erreur Stripe : #{e.message}"
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end
end
