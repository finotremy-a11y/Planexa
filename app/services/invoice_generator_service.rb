# frozen_string_literal: true

require "prawn"
require "prawn/table"

class InvoiceGeneratorService
  DEFAULT_TAX_RATE = 0.20

  def initialize(payment)
    @payment     = payment
    @company     = payment.company
    @client      = payment.client_user
    @appointment = payment.appointment
  end

  def call
    return @payment.invoice if @payment.invoice.present? # Idempotence

    invoice = nil

    ActiveRecord::Base.transaction do
      invoice   = create_invoice
      pdf_data  = generate_pdf(invoice)
      attach_pdf(invoice, pdf_data)
    end

    invoice
  rescue => e
    Rails.logger.error "[InvoiceGeneratorService] Échec pour payment ##{@payment.id}: #{e.message}"
    nil
  end

  private

  def create_invoice
    subtotal_cents   = @payment.amount_cents
    tax_amount_cents = (subtotal_cents * DEFAULT_TAX_RATE).round
    total_cents      = subtotal_cents + tax_amount_cents

    Invoice.create!(
      payment:          @payment,
      company:          @company,
      client_user:      @client,
      subtotal_cents:   subtotal_cents,
      tax_rate:         DEFAULT_TAX_RATE,
      tax_amount_cents: tax_amount_cents,
      total_cents:      total_cents,
      currency:         @payment.currency.upcase,
      issued_at:        Time.current
    )
  end

  def generate_pdf(invoice)
    Prawn::Document.new(page_size: "A4", margin: [ 50, 50, 50, 50 ]) do |pdf|
      draw_header(pdf)
      pdf.move_down 20
      pdf.stroke_horizontal_rule
      pdf.move_down 15

      draw_invoice_title(pdf, invoice)
      pdf.move_down 20

      draw_client_block(pdf)
      pdf.move_down 20
      pdf.stroke_horizontal_rule
      pdf.move_down 15

      draw_service_table(pdf, invoice)
      pdf.move_down 15

      draw_totals(pdf, invoice)
      pdf.move_down 40

      draw_footer(pdf)
    end.render
  end

  def draw_header(pdf)
    pdf.text @company.name, size: 18, style: :bold
    pdf.move_down 4
    pdf.text @company.address, size: 9, color: "555555"
    pdf.text "#{@company.zip_code} #{@company.city}", size: 9, color: "555555"
    pdf.text "SIRET : #{@company.siret}", size: 9, color: "555555"
  end

  def draw_invoice_title(pdf, invoice)
    pdf.text "FACTURE N° #{invoice.invoice_number}", size: 16, style: :bold, align: :right
    pdf.text "Émise le #{invoice.issued_at.strftime('%d/%m/%Y')}", size: 9, color: "666666", align: :right
    if @appointment
      pdf.text "RDV du #{@appointment.scheduled_at.strftime('%d/%m/%Y à %H:%M')}",
               size: 9, color: "666666", align: :right
    end
  end

  def draw_client_block(pdf)
    pdf.text "FACTURÉ À", size: 8, style: :bold, color: "888888"
    pdf.move_down 4
    if @client
      pdf.text @client.full_name, size: 10, style: :bold
      pdf.text @client.email, size: 9, color: "555555"
    else
      pdf.text "Client anonyme", size: 10
    end
  end

  def draw_service_table(pdf, invoice)
    service_name = @appointment&.service_type&.name || "Prestation de service"
    data = [
      [ "Description", "Montant HT" ],
      [ service_name, fmt_money(invoice.subtotal_cents, invoice.currency) ]
    ]

    pdf.table(data, width: pdf.bounds.width, cell_style: { size: 9, padding: [ 7, 10 ] }) do
      row(0).font_style        = :bold
      row(0).background_color  = "F0FDF4"
      row(0).text_color        = "166534"
      columns(1).align         = :right
      column(0).width          = pdf.bounds.width * 0.75
    end
  end

  def draw_totals(pdf, invoice)
    rows = [
      [ "Sous-total HT",                    fmt_money(invoice.subtotal_cents, invoice.currency),   false ],
      [ "TVA #{(invoice.tax_rate * 100).to_i}%", fmt_money(invoice.tax_amount_cents, invoice.currency), false ],
      [ "TOTAL TTC",                         fmt_money(invoice.total_cents, invoice.currency),     true  ]
    ]

    rows.each do |label, value, bold|
      pdf.text "#{label} : #{value}",
               align:  :right,
               size:   bold ? 11 : 9,
               style:  bold ? :bold : :normal
      pdf.move_down 4
    end
  end

  def draw_footer(pdf)
    pdf.stroke_horizontal_rule
    pdf.move_down 6
    pdf.text "Planexa • planexa.fr",
             size: 7, color: "999999", align: :center
    pdf.text "Paiement effectué par carte bancaire via Stripe. TVA applicable selon la réglementation en vigueur.",
             size: 7, color: "aaaaaa", align: :center
  end

  def fmt_money(cents, currency)
    symbol = currency.upcase == "EUR" ? "€" : currency
    "#{format('%.2f', cents / 100.0)} #{symbol}"
  end

  def attach_pdf(invoice, pdf_data)
    invoice.pdf.attach(
      io:           StringIO.new(pdf_data),
      filename:     "facture-#{invoice.invoice_number}.pdf",
      content_type: "application/pdf"
    )
  end
end
