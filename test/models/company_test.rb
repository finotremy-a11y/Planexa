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

  test "profil sante invalide sans specialite" do
    company = build(:company,
      professional_category: :healthcare_professional,
      health_specialty: nil,
      convention_sector: :sector_1)

    assert_not company.valid?
    assert company.errors[:health_specialty].any?
  end

  test "profil sante invalide sans conventionnement" do
    company = build(:company,
      professional_category: :healthcare_professional,
      health_specialty: "Orthophoniste",
      convention_sector: nil)

    assert_not company.valid?
    assert company.errors[:convention_sector].any?
  end

  test "profil sante valide avec specialite et conventionnement" do
    company = build(:company,
      professional_category: :healthcare_professional,
      health_specialty: "Psychologue",
      convention_sector: :sector_2)

    assert company.valid?
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

  # — Widget token —
  test "widget_token est généré automatiquement à la création" do
    company = create(:company)
    assert_not_nil company.widget_token
    assert_match(/\A[0-9a-f\-]{36}\z/, company.widget_token)
  end

  test "widget_token est unique" do
    c1 = create(:company)
    c2 = build(:company, widget_token: c1.widget_token)
    assert_not c2.valid?
    assert c2.errors[:widget_token].any?
  end

  test "regenerate_widget_token! change le token" do
    company = create(:company)
    old_token = company.widget_token
    company.regenerate_widget_token!
    assert_not_equal old_token, company.reload.widget_token
  end

  test "deux companies ont des tokens différents" do
    c1 = create(:company)
    c2 = create(:company)
    assert_not_equal c1.widget_token, c2.widget_token
  end

  test "next_available_slot retourne un creneau quand un employe qualifie est disponible" do
    company = create(:company)
    service = create(:service_type, company: company, duration_minutes: 30)
    employee = create(:employee, company: company)
    create(:employee_skill, employee: employee, service_type: service)

    create(
      :schedule,
      company: company,
      employee: employee,
      day_of_week: Time.current.wday,
      start_time: "00:00",
      end_time: "23:59",
      available: true,
      schedule_type: "recurring"
    )

    slot = company.next_available_slot(service_type: service, step_minutes: 30, max_checks: 4)

    assert_not_nil slot
    assert_equal service.id, slot[:service_type].id
    assert_equal employee.id, slot[:employee].id
    assert_in_delta Time.current.to_i, slot[:scheduled_at].to_i, 30.minutes
  end

  test "next_available_slot retourne nil sans employe qualifie" do
    company = create(:company)
    service = create(:service_type, company: company)

    slot = company.next_available_slot(service_type: service)

    assert_nil slot
  end
end
