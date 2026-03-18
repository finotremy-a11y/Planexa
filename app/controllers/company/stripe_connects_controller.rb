# frozen_string_literal: true

class Company::StripeConnectsController < Company::BaseController
  def connect
    if @company.stripe_account_id.present?
      account = Stripe::Account.retrieve(@company.stripe_account_id)
      if account.details_submitted
        return redirect_to company_root_path,
          notice: "Votre compte Stripe est déjà connecté."
      end
    else
      account = Stripe::Account.create(
        type: "express",
        country: "FR",
        email: @company.user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true }
        },
        business_type: "individual",
        metadata: { company_id: @company.id }
      )
      @company.update!(stripe_account_id: account.id)
    end

    account_link = Stripe::AccountLink.create(
      account: @company.stripe_account_id,
      refresh_url: refresh_company_stripe_connect_url,
      return_url: return_company_stripe_connect_url,
      type: "account_onboarding"
    )

    redirect_to account_link.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to company_settings_path,
      alert: "Erreur Stripe : #{e.message}"
  end

  def return
    account = Stripe::Account.retrieve(@company.stripe_account_id)
    if account.details_submitted
      @company.update!(stripe_onboarding_complete: true)
      redirect_to company_settings_path,
        notice: "✅ Votre compte Stripe est connecté ! Vous pouvez maintenant recevoir des paiements en ligne."
    else
      redirect_to company_settings_path,
        alert: "L'onboarding Stripe n'est pas complet. Veuillez recommencer."
    end
  end

  def refresh
    redirect_to connect_company_stripe_connect_path
  end
end
