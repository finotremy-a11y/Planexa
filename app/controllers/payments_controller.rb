# frozen_string_literal: true

# Gère le paiement en ligne après création d'un RDV (mode in_app)
class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment

  def new
    unless @appointment.requires_payment?
      return redirect_to confirmation_appointments_path(appointment_id: @appointment.id)
    end

    if @appointment.paid?
      return redirect_to confirmation_appointments_path(appointment_id: @appointment.id),
        notice: "Ce rendez-vous est déjà payé."
    end

    service = StripePaymentService.new(@appointment)
    @payment_intent = service.create_payment_intent
    @publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"]
  rescue StandardError => e
    redirect_to root_path, alert: "Erreur lors de la création du paiement : #{e.message}"
  end

  def create
    payment = Payment.find_by(stripe_payment_intent_id: params[:payment_intent_id])
    if payment&.succeeded?
      render json: {
        status: "success",
        redirect_url: confirmation_appointments_path(appointment_id: @appointment.id)
      }
    else
      render json: { status: "pending" }
    end
  end

  private

  def set_appointment
    @appointment = current_user.client_appointments.find(params[:appointment_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Rendez-vous introuvable."
  end
end
