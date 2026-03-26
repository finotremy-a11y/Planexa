# frozen_string_literal: true

FactoryBot.define do
  factory :discount_code do
    association :company
    association :client_user, factory: :user
    discount_type { :fixed }
    discount_value_cents { 1000 }
    expires_at { 30.days.from_now }

    trait :percentage do
      discount_type { :percentage }
      discount_value_cents { 1500 } # 15%
    end

    trait :used do
      used_at { 1.day.ago }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
