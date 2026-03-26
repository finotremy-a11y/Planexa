class User < ApplicationRecord
  # ── Devise ─────────────────────────────────────────────────────────────────
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable,
        :confirmable, :trackable

  # ── Enums ──────────────────────────────────────────────────────────────────
  enum :role, { client: 0, company_admin: 1, admin: 2 }
  enum :locale, { fr: "fr", en: "en", es: "es" }, default: :fr

  # ── Associations ───────────────────────────────────────────────────────────
  has_one  :company, dependent: :destroy
  has_many :client_appointments, class_name: "Appointment",
                                foreign_key: :client_user_id,
                                dependent: :nullify
  has_many :client_payments, class_name: "Payment",
                              foreign_key: :client_user_id,
                              dependent: :nullify
  has_many :reviews,          class_name: "Review",
                              foreign_key: :client_user_id,
                              dependent: :nullify
  has_many :waitlist_entries,  class_name: "WaitlistEntry",
                              foreign_key: :client_user_id,
                              dependent: :nullify
  has_many :loyalty_points,    class_name: "LoyaltyPoint",
                              foreign_key: :client_user_id,
                              dependent: :destroy
  has_many :discount_codes,    class_name: "DiscountCode",
                              foreign_key: :client_user_id,
                              dependent: :destroy
  has_many :client_invoices,    class_name: "Invoice",
                              foreign_key: :client_user_id,
                              dependent: :nullify
  has_many :push_subscriptions, class_name: "PushSubscription",
                              dependent: :destroy

  # ── Validations ────────────────────────────────────────────────────────────
  validates :first_name, :last_name, presence: true
  validates :role, :locale, presence: true

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

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email first_name last_name locale role updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company]
  end
end
