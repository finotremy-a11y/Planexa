class StripeSubscriptionService
  PRICE_ID = ENV["STRIPE_PRICE_ID"]  # 49€/mois
  TRIAL_DAYS = 14

  def initialize(company)
    @company = company
  end

  # Crée le customer Stripe + la session Checkout avec 14j d'essai
  def create_checkout_session(success_url:, cancel_url:)
    customer = find_or_create_customer

    Stripe::Checkout::Session.create(
      customer:              customer.id,
      payment_method_types:  ["card"],
      mode:                  "subscription",
      line_items: [{
        price:    PRICE_ID,
        quantity: 1
      }],
      subscription_data: {
        trial_period_days: TRIAL_DAYS,
        metadata: { company_id: @company.id }
      },
      success_url: success_url,
      cancel_url:  cancel_url,
      locale:      "fr",
      metadata:    { company_id: @company.id }
    )
  end

  # Crée le Billing Portal pour que l'entreprise gère son abonnement
  def create_billing_portal_session(return_url:)
    Stripe::BillingPortal::Session.create(
      customer:   @company.stripe_customer_id,
      return_url: return_url,
      locale:     "fr"
    )
  end

  private

  def find_or_create_customer
    if @company.stripe_customer_id.present?
      Stripe::Customer.retrieve(@company.stripe_customer_id)
    else
      customer = Stripe::Customer.create(
        email:    @company.user.email,
        name:     @company.name,
        metadata: { company_id: @company.id }
      )
      @company.update!(stripe_customer_id: customer.id)
      customer
    end
  end
end
