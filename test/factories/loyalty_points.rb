# frozen_string_literal: true

FactoryBot.define do
  factory :loyalty_point do
    association :client_user, factory: :user
    association :company
    points { 10 }
    reason { "earned" }

    trait :earned do
      reason { "earned" }
      association :appointment
    end

    trait :redeemed do
      points { -10 }
      reason { "redeemed" }
    end

    trait :manual do
      reason { "manual" }
    end

    trait :with_appointment do
      association :appointment
    end
  end
end
