FactoryBot.define do
  factory :conversation_message do
    association :conversation
    sender { conversation.client_user }
    body { "Bonjour, je vous ecris pour mon rendez-vous." }
  end
end
