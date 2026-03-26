# frozen_string_literal: true

# Canal Action Cable pour les notifications temps réel de l'espace entreprise.
# Chaque admin s'abonne au canal de sa propre entreprise.
# Les broadcasts sont déclenchés par le modèle Notification (via Turbo Streams).
class CompanyNotificationsChannel < ApplicationCable::Channel
  def subscribed
    company = Company.active.find_by(id: params[:company_id])

    if company && current_user.company_id == company.id
      stream_from "company_#{company.id}_notifications"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
