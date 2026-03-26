# frozen_string_literal: true

require "test_helper"

class GenerateInvoiceJobTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @client = create(:user, role: :client)
    @service_type = create(:service_type, company: @company, price_cents: 5000)
    @appointment = create(:appointment, :confirmed,
      company: @company,
      service_type: @service_type,
      client_user: @client)
    @payment = create(:payment, :succeeded,
      appointment: @appointment,
      client_user: @client,
      company: @company)
  end

  test "génère une facture quand le paiement existe" do
    assert_difference("Invoice.count", 1) do
      GenerateInvoiceJob.perform_now(@payment.id)
    end
  end

  test "ne fait rien si le paiement est introuvable" do
    assert_no_difference("Invoice.count") do
      GenerateInvoiceJob.perform_now(-1)
    end
  end

  test "ne duplique pas la facture si elle existe déjà" do
    create(:invoice, payment: @payment, company: @company, client_user: @client)

    assert_no_difference("Invoice.count") do
      GenerateInvoiceJob.perform_now(@payment.id)
    end
  end
end