FactoryBot.define do
  factory :employee do
    association :company
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    sequence(:email) { |n| "employee#{n}@example.com" }
    active     { true }
  end
end
