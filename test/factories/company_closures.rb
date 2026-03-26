FactoryBot.define do
  factory :company_closure do
    association :company
    starts_at { 2.days.from_now.beginning_of_day }
    ends_at { 2.days.from_now.end_of_day }
    reason { "Conge" }
    note { "Cabinet ferme exceptionnellement." }
  end
end
