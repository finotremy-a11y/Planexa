# frozen_string_literal: true

class Client::InvoicesController < Client::BaseController
  before_action :set_invoice, only: [ :show, :download ]

  def index
    @invoices = Invoice.for_client(current_user)
                       .includes(:company, payment: :appointment)
                       .recent
  end

  def show; end

  def download
    unless @invoice.pdf.attached?
      return redirect_to client_invoice_path(@invoice),
                         alert: "Le PDF de cette facture n'est pas encore disponible."
    end

    send_data @invoice.pdf.download,
              filename:    "facture-#{@invoice.invoice_number}.pdf",
              type:        "application/pdf",
              disposition: "attachment"
  end

  private

  def set_invoice
    @invoice = Invoice.for_client(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to client_invoices_path, alert: "Facture introuvable."
  end
end
