# frozen_string_literal: true

FactoryBot.define do
  factory :employee_absence do
    association :employee
    starts_at { 1.day.from_now.beginning_of_day }
    ends_at   { 3.days.from_now.end_of_day }
    reason    { "vacation" }
    note      { nil }

    trait :sick do
      reason { "sick" }
    end

    trait :training do
      reason { "training" }
    end

    trait :active_now do
      starts_at { 1.day.ago }
      ends_at   { 1.day.from_now }
    end

    trait :past do
      starts_at { 10.days.ago }
      ends_at   { 5.days.ago }
    end

    trait :with_note do
      note { "Absence prévue" }
    end
  end
end
