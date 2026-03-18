require "test_helper"

class CompanySettingTest < ActiveSupport::TestCase
  # — Validations —
  test "invalide sans booking_mode" do
    setting = build(:company_setting, booking_mode: nil)
    assert_not setting.valid?
  end

  test "invalide sans payment_mode" do
    setting = build(:company_setting, payment_mode: nil)
    assert_not setting.valid?
  end

  test "invalide sans assignment_mode" do
    setting = build(:company_setting, assignment_mode: nil)
    assert_not setting.valid?
  end

  test "valide avec attributs par défaut" do
    setting = build(:company_setting)
    assert setting.valid?
  end

  # — Méthodes booléennes —
  test "public_booking? retourne true quand booking_public" do
    setting = build(:company_setting, booking_mode: :booking_public)
    assert setting.public_booking?
  end

  test "public_booking? retourne false quand booking_private" do
    setting = build(:company_setting, booking_mode: :booking_private)
    assert_not setting.public_booking?
  end

  test "in_app_payment? retourne true quand payment_in_app" do
    setting = build(:company_setting, payment_mode: :payment_in_app)
    assert setting.in_app_payment?
  end

  test "in_app_payment? retourne false quand payment_external" do
    setting = build(:company_setting, payment_mode: :payment_external)
    assert_not setting.in_app_payment?
  end

  test "auto_assignment? retourne true quand assignment_automatic" do
    setting = build(:company_setting, assignment_mode: :assignment_automatic)
    assert setting.auto_assignment?
  end

  test "auto_assignment? retourne false quand assignment_manual" do
    setting = build(:company_setting, assignment_mode: :assignment_manual)
    assert_not setting.auto_assignment?
  end
end
