# frozen_string_literal: true

class BookingGroup < ApplicationRecord
  belongs_to :company
  belongs_to :client_user, class_name: "User", optional: true

  has_many :appointments, dependent: :destroy

  enum :status, { pending: 0, confirmed: 1, cancelled: 2, completed: 3 }

  monetize :total_amount_cents, with_currency: :eur

  validates :total_amount_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :for_company, ->(company) { where(company: company) }

  def total_duration_minutes
    appointments.sum(:duration_minutes)
  end

  def service_types
    ServiceType.where(id: appointments.select(:service_type_id))
  end

  def confirm_all!
    transaction do
      update!(status: :confirmed)
      appointments.each(&:confirmed!)
    end
  end

  def cancel_all!
    transaction do
      update!(status: :cancelled)
      appointments.each(&:cancelled!)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[company_id client_user_id status total_amount_cents created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company client_user appointments]
  end
end
