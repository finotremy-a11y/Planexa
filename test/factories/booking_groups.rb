FactoryBot.define do
  factory :booking_group do
    association :company
    association :client_user, factory: :user
    total_amount_cents { 5000 }
    currency           { "EUR" }
    status             { :pending }

    trait :confirmed do
      status { :confirmed }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :completed do
      status { :completed }
    end

    trait :anonymous do
      client_user { nil }
    end
  end
end
