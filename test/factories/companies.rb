FactoryBot.define do
  factory :company do
    association :user, factory: [ :user, :company_admin ]
    name     { Faker::Company.name }
    sequence(:siret) { |n| format("%014d", n) }
    address  { Faker::Address.street_address }
    city     { Faker::Address.city }
    zip_code { Faker::Address.zip_code[0..4] }
    status   { :active }

    after(:create) do |company|
      company.company_setting || company.create_company_setting
    end
  end
end
