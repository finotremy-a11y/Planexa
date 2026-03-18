FactoryBot.define do
  factory :appointment do
    association :company
    association :service_type
    scheduled_at     { 2.days.from_now.change(hour: 10, min: 0, sec: 0) }
    duration_minutes { 60 }
    status           { :pending }
    booking_source   { :online }
    urgent           { false }

    trait :confirmed do
      status { :confirmed }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :completed do
      status { :completed }
    end

    trait :urgent do
      urgent { true }
    end

    trait :with_client do
      association :client_user, factory: :user
    end

    trait :with_employee do
      association :employee
    end
  end
end
