FactoryBot.define do
  factory :service_type do
    association :company
    name             { Faker::Commerce.department }
    duration_minutes { [ 30, 60, 90 ].sample }
    price_cents      { Faker::Number.between(from: 1000, to: 10_000) }
    active           { true }
  end
end
