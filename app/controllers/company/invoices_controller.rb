# frozen_string_literal: true

require "csv"

class Company::InvoicesController < Company::BaseController
  before_action :set_invoice, only: [ :show, :download ]

  def index
    @year  = params[:year]&.to_i  || Date.current.year
    @month = params[:month]&.to_i || Date.current.month

    @invoices = @company.invoices
                        .includes(:client_user, payment: :appointment)
                        .for_month(@year, @month)
                        .recent

    @total_ht  = @invoices.sum(:subtotal_cents)
    @total_tva = @invoices.sum(:tax_amount_cents)
    @total_ttc = @invoices.sum(:total_cents)
  end

  def show; end

  def download
    unless @invoice.pdf.attached?
      return redirect_to company_invoice_path(@invoice),
                         alert: "Le PDF de cette facture n'est pas encore disponible."
    end

    send_data @invoice.pdf.download,
              filename:    "facture-#{@invoice.invoice_number}.pdf",
              type:        "application/pdf",
              disposition: "attachment"
  end

  def export_csv
    year  = params[:year]&.to_i  || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    invoices = @company.invoices
                       .includes(:client_user)
                       .for_month(year, month)
                       .recent

    csv_data = CSV.generate(headers: true, col_sep: ";", encoding: "UTF-8") do |csv|
      csv << [ "N° Facture", "Date", "Client", "Montant HT (€)", "TVA (€)", "Total TTC (€)" ]

      invoices.each do |inv|
        csv << [
          inv.invoice_number,
          inv.issued_at.strftime("%d/%m/%Y"),
          inv.client_user&.full_name || "—",
          format("%.2f", inv.subtotal_cents  / 100.0),
          format("%.2f", inv.tax_amount_cents / 100.0),
          format("%.2f", inv.total_cents      / 100.0)
        ]
      end
    end

    filename = "factures_#{year}-#{format('%02d', month)}_#{@company.name.parameterize}.csv"
    send_data "\xEF\xBB\xBF#{csv_data}",
              filename:    filename,
              type:        "text/csv; charset=utf-8",
              disposition: "attachment"
  end

  private

  def set_invoice
    @invoice = @company.invoices.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end
end
