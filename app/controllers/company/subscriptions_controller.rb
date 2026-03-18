class Company::SubscriptionsController < Company::BaseController
  def show
    @subscription = @company.subscription
  end

  def new
    if @company.subscription_active?
      redirect_to company_subscription_path,
        notice: "Vous avez déjà un abonnement actif."
    end
  end

  def create
    service = StripeSubscriptionService.new(@company)

    session = service.create_checkout_session(
      success_url: company_subscription_url + "?success=true",
      cancel_url:  new_company_subscription_url + "?canceled=true"
    )

    redirect_to session.url, allow_other_host: true
  rescue ::Stripe::StripeError => e
    Rails.logger.error "[Stripe Checkout] Erreur: #{e.message}"
    redirect_to new_company_subscription_path,
      alert: "Erreur lors de la création de l'abonnement : #{e.message}"
  end

  def destroy
    subscription = @company.subscription
    return redirect_to company_subscription_path,
      alert: "Aucun abonnement actif." unless subscription

    ::Stripe::Subscription.cancel(subscription.stripe_subscription_id)
    subscription.update!(status: :canceled)
    @company.suspended!

    redirect_to company_subscription_path,
      notice: "Votre abonnement a été annulé."
  rescue ::Stripe::StripeError => e
    redirect_to company_subscription_path, alert: "Erreur : #{e.message}"
  end

  def checkout
    create
  end

  def portal
    service = StripeSubscriptionService.new(@company)
    portal_session = service.create_billing_portal_session(
      return_url: company_subscription_url
    )
    redirect_to portal_session.url, allow_other_host: true
  rescue ::Stripe::StripeError => e
    redirect_to company_subscription_path, alert: "Erreur : #{e.message}"
  end
end
