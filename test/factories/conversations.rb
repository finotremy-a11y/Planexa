FactoryBot.define do
  factory :conversation do
    association :company
    association :client_user, factory: :user
  end
end
