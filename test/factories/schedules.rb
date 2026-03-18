FactoryBot.define do
  factory :schedule do
    association :employee
    association :company
    day_of_week   { 1 }
    start_time    { "08:00" }
    end_time      { "18:00" }
    available     { true }
    schedule_type { "recurring" }
  end
end
