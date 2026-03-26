FactoryBot.define do
  factory :waitlist_entry do
    association :company
    association :service_type
    client_name  { Faker::Name.name }
    sequence(:client_email) { |n| "waitlist#{n}@example.com" }

    trait :with_client do
      association :client_user, factory: :user
      client_email { nil }
      client_name  { nil }
    end

    trait :notified do
      notified_at { 1.hour.ago }
    end

    trait :expired do
      expired_at { 1.hour.ago }
    end

    trait :with_preferred_date do
      preferred_date { 3.days.from_now.to_date }
    end
  end
end
