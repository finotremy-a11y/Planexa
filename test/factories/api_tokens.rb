FactoryBot.define do
  factory :api_token do
    association :company
    sequence(:name) { |n| "Token #{n}" }
    token_digest { ApiToken.digest("ppat_test_#{SecureRandom.hex(8)}") }
    scopes { ["read:appointments"] }
    expires_at { 3.months.from_now }
  end
end
