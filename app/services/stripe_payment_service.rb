# frozen_string_literal: true

# Crée un PaymentIntent Stripe Connect pour qu'un client paie une entreprise.
class StripePaymentService
  def initialize(appointment)
    @appointment = appointment
    @company     = appointment.company
    @service     = appointment.service_type
  end

  def create_payment_intent
    raise "Compte Stripe non connecté" unless @company.stripe_account_id.present?
    raise "Onboarding Stripe incomplet" unless @company.stripe_onboarding_complete?

    amount_to_charge = @appointment.payment_amount_cents

    intent = Stripe::PaymentIntent.create(
      {
        amount:   amount_to_charge,
        currency: "eur",
        transfer_data: {
          destination: @company.stripe_account_id
        },
        metadata: {
          appointment_id: @appointment.id,
          company_id:     @company.id,
          service_name:   @service.name,
          payment_scope:  @service.deposit_required? ? "deposit" : "full"
        },
        description: "#{@service.name} — #{@company.name}"
      },
      { idempotency_key: "payment_intent_appt_#{@appointment.id}" }
    )

    Payment.create!(
      appointment:              @appointment,
      client_user:              @appointment.client_user,
      company:                  @company,
      stripe_payment_intent_id: intent.id,
      amount_cents:             amount_to_charge,
      currency:                 "eur",
      status:                   :pending
    )

    intent
  rescue Stripe::StripeError => e
    Rails.logger.error "[Stripe Payment] Erreur: #{e.message}"
    raise e
  end
end
