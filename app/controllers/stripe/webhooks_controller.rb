module Stripe
  class WebhooksController < ApplicationController
    # Désactiver CSRF pour les webhooks
    skip_before_action :verify_authenticity_token

    def create
      payload    = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      begin
        event = ::Stripe::Webhook.construct_event(
          payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
        )
      rescue ::Stripe::SignatureVerificationError => e
        Rails.logger.error "[Stripe Webhook] Signature invalide: #{e.message}"
        return render json: { error: "Signature invalide" }, status: 422
      end

      handle_event(event)
      render json: { received: true }
    end

    private

    def handle_event(event)
      case event["type"]

      # ── Abonnement créé (début essai ou paiement direct) ─────────────────
      when "customer.subscription.created"
        stripe_sub = event.data.object
        company    = Company.find_by(stripe_customer_id: stripe_sub.customer)
        return unless company

        subscription = company.subscription || company.build_subscription
        subscription.update!(
          stripe_subscription_id: stripe_sub.id,
          stripe_price_id:        stripe_sub.items.data.first.price.id,
          status:                 stripe_sub.status,
          trial_ends_at:          stripe_sub.trial_end ? Time.at(stripe_sub.trial_end) : nil,
          current_period_end:     Time.at(stripe_sub.current_period_end)
        )
        company.active!
        CompanyMailer.welcome_trial(company).deliver_later if stripe_sub.status == "trialing"

      # ── Paiement réussi ──────────────────────────────────────────────────
      when "invoice.payment_succeeded"
        invoice = event.data.object
        return unless invoice.subscription

        subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
        return unless subscription

        subscription.reactivate! if subscription.suspended? || subscription.past_due?
        subscription.update!(
          status:             :active,
          current_period_end: Time.at(invoice.lines.data.first.period.end)
        )

      # ── Paiement échoué ──────────────────────────────────────────────────
      when "invoice.payment_failed"
        invoice = event.data.object
        return unless invoice.subscription

        subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
        return unless subscription

        subscription.update!(status: :past_due)
        CompanyMailer.payment_failed(subscription.company).deliver_later

      # ── Abonnement annulé ─────────────────────────────────────────────────
      when "customer.subscription.deleted"
        stripe_sub   = event.data.object
        subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
        return unless subscription

        subscription.update!(status: :canceled)
        subscription.company.suspended!
        CompanyMailer.subscription_canceled(subscription.company).deliver_later

      # ── Checkout terminé (récupération stripe_subscription_id) ───────────
      when "checkout.session.completed"
        session    = event.data.object
        company_id = session.metadata["company_id"]
        company    = Company.find_by(id: company_id)
        return unless company && session.subscription

        company.update!(stripe_customer_id: session.customer) if company.stripe_customer_id.blank?

      # ── Paiement client (Stripe Connect) — confirmation ──────────────────
      when "payment_intent.succeeded"
        payment_intent = event.data.object
        payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
        return unless payment

        payment.update!(status: :succeeded, paid_at: Time.current)
        appointment = payment.appointment
        appointment.confirmed!
        ClientMailer.appointment_confirmed(appointment).deliver_later
        CompanyMailer.new_appointment(appointment).deliver_later
        AppointmentReminderJob.set(wait_until: appointment.scheduled_at - 24.hours)
                              .perform_later(appointment.id)

      else
        Rails.logger.info "[Stripe Webhook] Événement non géré: #{event["type"]}"
      end
    end
  end
end
