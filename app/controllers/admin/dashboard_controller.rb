# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    # Entreprises
    @total_companies     = Company.count
    @active_companies    = Company.active.count
    @suspended_companies = Company.suspended.count

    # Abonnements
    @active_subs   = Subscription.active.count
    @trialing_subs = Subscription.trialing.count
    @past_due_subs = Subscription.past_due.count
    @canceled_subs = Subscription.canceled.count

    # MRR estimé (abonnements actifs + en essai × 49€)
    @mrr = (@active_subs + @trialing_subs) * 49

    # Clients
    @total_clients = User.client.count

    # Rendez-vous
    @total_appointments = Appointment.count
    @today_appointments = Appointment.today.count

    # Évolution inscriptions (30 derniers jours)
    @new_companies_30d = Company.where("created_at >= ?", 30.days.ago).count
    @new_clients_30d   = User.client.where("created_at >= ?", 30.days.ago).count

    # Dernières entreprises inscrites
    @recent_companies = Company.includes(:user, :subscription)
                               .order(created_at: :desc)
                               .limit(8)

    # Abonnements en souffrance
    @overdue_subscriptions = Subscription.past_due
                                         .includes(:company)
                                         .order(updated_at: :asc)
  end

  def metrics
    # Données pour graphiques (JSON)
    @companies_by_day = Company.where("created_at >= ?", 30.days.ago)
                               .group("DATE(created_at)")
                               .count

    @revenue_by_month = Subscription.active
                                    .where("created_at >= ?", 6.months.ago)
                                    .group("DATE_TRUNC('month', created_at)")
                                    .count

    render json: {
      companies_by_day: @companies_by_day,
      revenue_by_month: @revenue_by_month
    }
  end

  def export_csv
    companies = Company.includes(:user, :subscription).order(:name)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Nom", "SIRET", "Ville", "Email", "Statut", "Abonnement", "Date inscription" ]
      companies.each do |company|
        csv << [
          company.name,
          company.siret,
          company.city,
          company.user.email,
          company.status,
          company.subscription&.status || "aucun",
          company.created_at.strftime("%d/%m/%Y")
        ]
      end
    end

    send_data csv_data,
              filename: "planify_pro_entreprises_#{Date.today}.csv",
              type: "text/csv"
  end
end
