# frozen_string_literal: true

class LoyaltyPoint < ApplicationRecord
  belongs_to :client_user, class_name: "User"
  belongs_to :company
  belongs_to :appointment, optional: true

  REASONS = %w[earned redeemed expired manual].freeze

  validates :points, presence: true, numericality: { other_than: 0 }
  validates :reason, inclusion: { in: REASONS }

  scope :earned,   -> { where(reason: "earned") }
  scope :redeemed, -> { where(reason: "redeemed") }
  scope :for_company, ->(company) { where(company: company) }

  def self.balance_for(user, company)
    where(client_user: user, company: company).sum(:points)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[client_user_id company_id appointment_id points reason created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[client_user company appointment]
  end
end
