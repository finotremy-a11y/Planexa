FactoryBot.define do
  factory :employee_skill do
    association :employee
    association :service_type
    level { :intermediate }
  end
end
