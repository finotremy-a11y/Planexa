# frozen_string_literal: true

# Public controller — allows clients to join waitlist and confirm via token
class WaitlistEntriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :confirm, :confirmed, :submitted ]

  before_action :set_company, only: [ :new, :create ]

  # GET /liste-attente/nouveau?company_id=X&service_type_id=Y
  def new
    @service_types = @company.service_types.active
    @entry = WaitlistEntry.new(
      company: @company,
      service_type_id: params[:service_type_id]
    )
  end

  # POST /liste-attente
  def create
    @entry = @company.waitlist_entries.new(waitlist_params)
    @entry.client_user = current_user if user_signed_in?

    if @entry.save
      redirect_to waitlist_submitted_path, notice: "Inscription en liste d'attente confirmée !"
    else
      @service_types = @company.service_types.active
      render :new, status: :unprocessable_entity
    end
  end

  # GET /liste-attente/confirmer/:token
  def confirm
    @entry = WaitlistEntry.find_by!(token: params[:token])

    if @entry.expired?
      redirect_to root_path, alert: "Ce lien a expiré."
      return
    end

    unless @entry.notified?
      redirect_to root_path, alert: "Cette inscription n'est pas encore notifiée."
      return
    end

    if @entry.notification_expired?
      @entry.expire!
      redirect_to root_path, alert: "Le délai de 24h pour confirmer est dépassé."
      return
    end

    # Rediriger vers le formulaire de prise de RDV avec les infos pré-remplies
    @entry.expire! # Marquer comme consommée
    redirect_to new_appointment_path(
      company_id: @entry.company_id,
      service_type_id: @entry.service_type_id
    ), notice: "Créneau réservé ! Complétez votre rendez-vous."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Lien invalide."
  end

  # GET /liste-attente/merci
  def submitted; end

  # GET /liste-attente/confirme
  def confirmed; end

  private

  def set_company
    @company = Company.find(params[:company_id] || params.dig(:waitlist_entry, :company_id))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Entreprise introuvable."
  end

  def waitlist_params
    params.require(:waitlist_entry).permit(:service_type_id, :client_email,
                                           :client_name, :preferred_date)
  end
end
