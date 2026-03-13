class User < ApplicationRecord
  # ── Devise ─────────────────────────────────────────────────────────────────
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable,
        :confirmable, :trackable

  # ── Enums ──────────────────────────────────────────────────────────────────
  enum :role, { client: 0, company_admin: 1, admin: 2 }

  # ── Associations ───────────────────────────────────────────────────────────
  has_one  :company, dependent: :destroy
  has_many :client_appointments, class_name: "Appointment",
                                foreign_key: :client_user_id,
                                dependent: :nullify
  has_many :client_payments, class_name: "Payment",
                              foreign_key: :client_user_id,
                              dependent: :nullify

  # ── Validations ────────────────────────────────────────────────────────────
  validates :first_name, :last_name, presence: true
  validates :role, presence: true

  # ── Méthodes ───────────────────────────────────────────────────────────────
  def full_name
    "#{first_name} #{last_name}"
  end

  def company_active?
    company_admin? && company&.active?
  end

  def company_suspended?
    company_admin? && company&.suspended?
  end
end
