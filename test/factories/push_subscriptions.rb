# test/factories/push_subscriptions.rb
FactoryBot.define do
  factory :push_subscription do
    user { association :user }
    company { association :company }
    endpoint { "https://fcm.googleapis.com/fcm/send/#{SecureRandom.hex(32)}" }
    auth { SecureRandom.base64(32) }
    p256dh { SecureRandom.base64(65) }
  end
end
