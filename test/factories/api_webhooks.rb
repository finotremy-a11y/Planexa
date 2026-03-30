FactoryBot.define do
  factory :api_webhook do
    association :company
    url { "https://example.org/planexa-webhook" }
    events { ["appointment.created"] }
    secret { SecureRandom.hex(32) }
    active { true }
  end
end
