FactoryBot.define do
  factory :payment do
    association :appointment
    association :client_user, factory: :user
    association :company
    sequence(:stripe_payment_intent_id) { |n| "pi_test_#{n}" }
    amount_cents { 5000 }
    currency     { "eur" }
    status       { :pending }

    trait :succeeded do
      status  { :succeeded }
      paid_at { Time.current }
    end

    trait :failed do
      status { :failed }
    end

    trait :refunded do
      status { :refunded }
    end
  end
end
