require "test_helper"

class InvoiceGeneratorServiceTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @client = create(:user, role: :client)
    @service_type = create(:service_type, company: @company, name: "Coupe signature", price_cents: 5000)
    @appointment = create(:appointment, :confirmed,
      company: @company,
      service_type: @service_type,
      client_user: @client,
      scheduled_at: 2.days.from_now.change(hour: 14, min: 0))
    @payment = create(:payment, :succeeded,
      appointment: @appointment,
      client_user: @client,
      company: @company,
      amount_cents: 5000,
      currency: "eur")
  end

  test "call crée une facture et attache un PDF" do
    invoice = nil

    assert_difference("Invoice.count", 1) do
      invoice = InvoiceGeneratorService.new(@payment).call
    end

    assert_not_nil invoice
    assert_equal @payment, invoice.payment
    assert_equal @company, invoice.company
    assert_equal @client, invoice.client_user
    assert_equal 5000, invoice.subtotal_cents
    assert_equal 1000, invoice.tax_amount_cents
    assert_equal 6000, invoice.total_cents
    assert_equal "EUR", invoice.currency
    assert invoice.pdf.attached?
  end

  test "call est idempotent si la facture existe déjà" do
    first_invoice = InvoiceGeneratorService.new(@payment).call

    assert_no_difference("Invoice.count") do
      second_invoice = InvoiceGeneratorService.new(@payment).call
      assert_equal first_invoice, second_invoice
    end
  end

  test "le PDF est généré et nommé avec le numéro de facture" do
    invoice = InvoiceGeneratorService.new(@payment).call
    pdf_data = invoice.pdf.download

    assert invoice.pdf.attached?
    assert_equal "facture-#{invoice.invoice_number}.pdf", invoice.pdf.filename.to_s
    assert_includes pdf_data, "%PDF"
  end

  test "retourne nil en cas d'erreur pendant la génération" do
    Prawn::Document.any_instance.stubs(:render).raises(StandardError, "PDF broken")

    assert_no_difference("Invoice.count") do
      assert_nil InvoiceGeneratorService.new(@payment).call
    end
  end
end