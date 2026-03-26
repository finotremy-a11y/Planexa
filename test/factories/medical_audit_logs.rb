FactoryBot.define do
  factory :medical_audit_log do
    association :company
    association :user
    action { "medical_profile_updated" }
    record_type { "Company" }
    record_id { 1 }
    metadata { { source: "test" } }

    after(:build) do |log|
      log.record_id = log.company.id if log.company&.id.present?
    end
  end
end
