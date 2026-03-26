# frozen_string_literal: true

class Invoice < ApplicationRecord
  belongs_to :payment
  belongs_to :company
  belongs_to :client_user, class_name: "User", optional: true

  has_one_attached :pdf

  monetize :subtotal_cents,   with_currency: ->(i) { i.currency }
  monetize :tax_amount_cents, with_currency: ->(i) { i.currency }
  monetize :total_cents,      with_currency: ->(i) { i.currency }

  validates :invoice_number, presence: true, uniqueness: true
  validates :issued_at,      presence: true
  validates :subtotal_cents, :tax_amount_cents, :total_cents,
            numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  before_validation :generate_invoice_number, on: :create

  scope :for_company, ->(company) { where(company: company) }
  scope :for_client,  ->(user)    { where(client_user: user) }
  scope :for_month,   ->(year, month) {
    start_date = Date.new(year.to_i, month.to_i, 1)
    where(issued_at: start_date.beginning_of_day..start_date.end_of_month.end_of_day)
  }
  scope :recent, -> { order(issued_at: :desc) }

  private

  def generate_invoice_number
    return if invoice_number.present?

    year = Date.current.year
    last_invoice_number = Invoice.where("invoice_number LIKE ?", "FAC-#{year}-%")
                                 .order(Arel.sql("invoice_number DESC"))
                                 .limit(1)
                                 .pick(:invoice_number)
    last_seq = last_invoice_number&.split("-")&.last.to_i
    seq = last_seq + 1
    self.invoice_number = format("FAC-%d-%04d", year, seq)
  end
end
