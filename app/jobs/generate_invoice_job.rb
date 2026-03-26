# frozen_string_literal: true

class GenerateInvoiceJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    payment = Payment.find_by(id: payment_id)
    return unless payment
    return if payment.invoice.present? # Idempotence

    InvoiceGeneratorService.new(payment).call
  end
end
