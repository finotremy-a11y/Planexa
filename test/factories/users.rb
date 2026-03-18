FactoryBot.define do
  factory :user do
    first_name    { Faker::Name.first_name }
    last_name     { Faker::Name.last_name }
    sequence(:email) { |n| "user#{n}@example.com" }
    password      { "password123" }
    confirmed_at  { Time.current }
    role          { :client }

    trait :company_admin do
      role { :company_admin }
    end

    trait :admin do
      role { :admin }
    end
  end
end
