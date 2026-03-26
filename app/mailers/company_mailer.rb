class CompanyMailer < ApplicationMailer
  # Bienvenue + début période d'essai
  def welcome_trial(company)
    @company = company
    @user    = company.user
    @trial_ends_at = company.subscription&.trial_ends_at
    with_recipient_locale(@user) do
      mail(to: @user.email, subject: t("mailers.company.welcome_trial.subject"))
    end
  end

  # Fin d'essai dans 3 jours
  def trial_ending_soon(company)
    @company   = company
    @user      = company.user
    @days_left = company.subscription&.days_until_trial_ends
    with_recipient_locale(@user) do
      mail(to: @user.email, subject: t("mailers.company.trial_ending_soon.subject", days_left: @days_left))
    end
  end

  # Paiement abonnement échoué
  def payment_failed(company)
    @company = company
    @user    = company.user
    with_recipient_locale(@user) do
      mail(to: @user.email, subject: t("mailers.company.payment_failed.subject"))
    end
  end

  # Compte suspendu
  def account_suspended(company)
    @company = company
    @user    = company.user
    with_recipient_locale(@user) do
      mail(to: @user.email, subject: t("mailers.company.account_suspended.subject"))
    end
  end

  # Compte réactivé après paiement
  def account_reactivated(company)
    @company = company
    @user    = company.user
    with_recipient_locale(@user) do
      mail(to: @user.email, subject: t("mailers.company.account_reactivated.subject"))
    end
  end

  # Abonnement annulé
  def subscription_canceled(company)
    @company = company
    @user    = company.user
    with_recipient_locale(@user) do
      mail(to: @user.email, subject: t("mailers.company.subscription_canceled.subject"))
    end
  end

  # Nouveau RDV reçu (notification entreprise)
  def new_appointment(appointment)
    @appointment = appointment
    @company     = appointment.company
    with_recipient_locale(@company.user) do
      mail(
        to: @company.user.email,
        subject: t("mailers.company.new_appointment.subject", datetime: I18n.l(appointment.scheduled_at, format: :short))
      )
    end
  end

  # Récap hebdomadaire de performance entreprise
  def weekly_performance_summary(company, period_start: 1.week.ago.beginning_of_day, period_end: Time.current.end_of_day)
    @company = company
    @user = company.user
    @period_start = period_start.to_date
    @period_end = period_end.to_date

    period = period_start..period_end
    appointments_scope = company.appointments.where(created_at: period)

    @weekly_bookings = appointments_scope.online.count
    @weekly_cancellations = company.appointments.cancelled.where(updated_at: period).count
    @weekly_reviews = company.reviews.published.where(published_at: period).count
    @weekly_estimated_revenue_eur = appointments_scope.online
                                               .where.not(status: :cancelled)
                                               .joins(:service_type)
                                               .sum("service_types.price_cents") / 100.0

    with_recipient_locale(@user) do
      mail(to: @user.email, subject: t("mailers.company.weekly_performance_summary.subject"))
    end
  end
end
