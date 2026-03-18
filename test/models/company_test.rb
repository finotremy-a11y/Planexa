require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  # — Associations —
  test "belongs_to user" do
    company = build(:company, user: nil)
    assert_not company.valid?
  end

  test "has_many employees" do
    company = create(:company)
    employee = create(:employee, company: company)
    assert_includes company.employees, employee
  end

  test "has_many service_types" do
    company = create(:company)
    service = create(:service_type, company: company)
    assert_includes company.service_types, service
  end

  test "has_many appointments" do
    company = create(:company)
    service = create(:service_type, company: company)
    appt = create(:appointment, company: company, service_type: service)
    assert_includes company.appointments, appt
  end

  # — Validations —
  test "invalid without name" do
    company = build(:company, name: "")
    assert_not company.valid?
  end

  test "invalid without siret" do
    company = build(:company, siret: "")
    assert_not company.valid?
  end

  test "invalid without address" do
    company = build(:company, address: "")
    assert_not company.valid?
  end

  test "invalid without city" do
    company = build(:company, city: "")
    assert_not company.valid?
  end

  test "invalid without zip_code" do
    company = build(:company, zip_code: "")
    assert_not company.valid?
  end

  test "siret de moins de 14 chiffres est invalide" do
    company = build(:company, siret: "1234")
    assert_not company.valid?
    assert_includes company.errors[:siret], "doit contenir 14 chiffres"
  end

  test "siret de 14 chiffres est valide" do
    company = build(:company, siret: "12345678901234")
    assert company.valid?
  end

  test "company_setting est créé après la création" do
    user    = create(:user, :company_admin)
    company = create(:company, user: user)
    assert_not_nil company.company_setting
  end

  test "subscription_active? retourne true avec abonnement actif" do
    company = create(:company)
    create(:subscription, company: company, status: :active)
    assert company.subscription_active?
  end

  test "subscription_active? retourne false sans abonnement" do
    company = create(:company)
    assert_not company.subscription_active?
  end
end
