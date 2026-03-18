FactoryBot.define do
  factory :subscription do
    association :company
    sequence(:stripe_subscription_id) { |n| "sub_test_#{n}" }
    sequence(:stripe_price_id)        { |n| "price_test_#{n}" }
    status               { :active }
    current_period_end   { 30.days.from_now }

    trait :trialing do
      status        { :trialing }
      trial_ends_at { 14.days.from_now }
    end

    trait :past_due do
      status { :past_due }
    end

    trait :suspended do
      status       { :suspended }
      suspended_at { Time.current }
    end
  end
end
