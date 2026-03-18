FactoryBot.define do
  factory :company_setting do
    association :company
    booking_mode    { :booking_public }
    payment_mode    { :payment_external }
    assignment_mode { :assignment_automatic }
  end
end
