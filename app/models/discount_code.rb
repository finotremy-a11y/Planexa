# frozen_string_literal: true

class DiscountCode < ApplicationRecord
  belongs_to :company
  belongs_to :client_user, class_name: "User"

  enum :discount_type, { percentage: 0, fixed: 1 }

  validates :code, presence: true, uniqueness: true
  validates :discount_value_cents, numericality: { greater_than: 0 }
  validates :expires_at, presence: true

  scope :usable,  -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :used,    -> { where.not(used_at: nil) }
  scope :expired, -> { where(used_at: nil).where("expires_at <= ?", Time.current) }
  scope :for_company, ->(company) { where(company: company) }

  before_validation :generate_code, on: :create

  def usable?
    used_at.nil? && expires_at > Time.current
  end

  def used?
    used_at.present?
  end

  def expired?
    used_at.nil? && expires_at <= Time.current
  end

  def use!
    update!(used_at: Time.current)
  end

  def discount_display
    if percentage?
      "#{discount_value_cents / 100}%"
    else
      ActionController::Base.helpers.number_to_currency(
        discount_value_cents / 100.0, unit: "€", separator: ",", format: "%n %u"
      )
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[code client_user_id company_id discount_type used_at expires_at created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[client_user company]
  end

  private

  def generate_code
    self.code = "FIDELITE-#{SecureRandom.alphanumeric(8).upcase}" if code.blank?
  end
end
