class Payment < ApplicationRecord
  belongs_to :appointment
  belongs_to :client_user, class_name: "User"
  belongs_to :company

  enum :status, { pending: 0, succeeded: 1, failed: 2, refunded: 3 }

  monetize :amount_cents, with_currency: ->(p) { p.currency }

  validates :stripe_payment_intent_id, presence: true, uniqueness: true
  validates :amount_cents,             numericality: { greater_than: 0 }

  scope :successful, -> { where(status: :succeeded) }

  def stripe_payment_intent
    @stripe_payment_intent ||= Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
  end
end
