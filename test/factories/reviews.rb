FactoryBot.define do
  factory :review do
    association :appointment
    association :company
    association :client_user, factory: :user

    token      { SecureRandom.urlsafe_base64(32) }
    expires_at { 30.days.from_now }

    trait :submitted do
      rating       { rand(4..5) }
      comment      { Faker::Lorem.sentence }
      submitted_at { 1.day.ago }
      published_at { 1.day.ago }
    end

    trait :pending do
      rating       { nil }
      submitted_at { nil }
      published_at { nil }
    end

    trait :unpublished do
      rating       { 4 }
      submitted_at { 1.day.ago }
      published_at { nil }
    end

    trait :expired do
      expires_at { 2.days.ago }
    end
  end
end
