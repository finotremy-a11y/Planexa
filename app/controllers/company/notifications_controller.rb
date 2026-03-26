# frozen_string_literal: true

# Gestion des notifications temps réel dans l'espace entreprise.
class Company::NotificationsController < Company::BaseController
  # GET /company/notifications
  def index
    @notifications = @company.notifications.includes(:notifiable).recent
    # Marquer toutes comme lues à la consultation de la page
    @company.notifications.unread.update_all(read_at: Time.current)
  end

  # PATCH /company/notifications/:id/marquer-lu
  def mark_read
    notification = @company.notifications.find(params[:id])
    notification.mark_as_read!
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # PATCH /company/notifications/tout-marquer-lu
  def mark_all_read
    @company.notifications.unread.update_all(read_at: Time.current)
    redirect_to company_notifications_path,
      notice: "Toutes les notifications ont été marquées comme lues."
  end
end
