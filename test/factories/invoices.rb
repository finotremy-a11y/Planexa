FactoryBot.define do
  factory :invoice do
    association :payment, :succeeded
    association :company
    association :client_user, factory: :user
    subtotal_cents   { 5000 }
    tax_rate         { 0.20 }
    tax_amount_cents { 1000 }
    total_cents      { 6000 }
    currency         { "EUR" }
    issued_at        { Time.current }

    trait :with_pdf do
      after(:create) do |invoice|
        invoice.pdf.attach(
          io:           StringIO.new("%PDF-1.4 fake"),
          filename:     "facture-#{invoice.invoice_number}.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
