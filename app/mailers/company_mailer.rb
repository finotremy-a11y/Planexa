class CompanyMailer < ApplicationMailer
  # Bienvenue + début période d'essai
  def welcome_trial(company)
    @company = company
    @user    = company.user
    @trial_ends_at = company.subscription&.trial_ends_at
    mail(to: @user.email, subject: "Bienvenue sur Planify Pro — Votre essai gratuit commence !")
  end

  # Fin d'essai dans 3 jours
  def trial_ending_soon(company)
    @company   = company
    @user      = company.user
    @days_left = company.subscription&.days_until_trial_ends
    mail(to: @user.email, subject: "Votre essai Planify Pro se termine dans #{@days_left} jours")
  end

  # Paiement abonnement échoué
  def payment_failed(company)
    @company = company
    @user    = company.user
    mail(to: @user.email, subject: "⚠️ Échec du paiement — Action requise")
  end

  # Compte suspendu
  def account_suspended(company)
    @company = company
    @user    = company.user
    mail(to: @user.email, subject: "Votre compte Planify Pro a été suspendu")
  end

  # Compte réactivé après paiement
  def account_reactivated(company)
    @company = company
    @user    = company.user
    mail(to: @user.email, subject: "✅ Votre compte Planify Pro est réactivé")
  end

  # Abonnement annulé
  def subscription_canceled(company)
    @company = company
    @user    = company.user
    mail(to: @user.email, subject: "Votre abonnement Planify Pro a été annulé")
  end

  # Nouveau RDV reçu (notification entreprise)
  def new_appointment(appointment)
    @appointment = appointment
    @company     = appointment.company
    mail(
      to:      @company.user.email,
      subject: "Nouveau rendez-vous — #{appointment.scheduled_at.strftime('%d/%m à %Hh%M')}"
    )
  end
end
