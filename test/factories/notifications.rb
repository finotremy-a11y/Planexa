FactoryBot.define do
  factory :notification do
    association :company
    kind { :new_booking }
    read_at { nil }

    trait :read do
      read_at { 1.hour.ago }
    end

    trait :cancellation do
      kind { :cancellation }
    end

    trait :urgent do
      kind { :urgent }
    end
  end
end
