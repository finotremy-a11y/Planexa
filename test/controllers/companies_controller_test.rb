# frozen_string_literal: true

require "test_helper"

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @company = create(:company)
    @company.setting.update!(booking_mode: :booking_public)
    create(:service_type, company: @company)
  end

  test "GET show retourne 200 sans authentification" do
    get company_public_path(@company)
    assert_response :success
  end

  test "GET show retourne 200 en étant connecté" do
    sign_in create(:user, role: :client)
    get company_public_path(@company)
    assert_response :success
  end

  test "GET show avec une entreprise inactive retourne 404" do
    @company.update!(status: :suspended)
    get company_public_path(@company)
    assert_response :not_found
  end

  test "GET show avec un id inexistant retourne 404" do
    get company_public_path(id: 0)
    assert_response :not_found
  end

  test "GET show affiche le CTA du prochain creneau si disponibilite" do
    service = @company.service_types.first
    employee = create(:employee, company: @company)
    create(:employee_skill, employee: employee, service_type: service)
    create(
      :schedule,
      company: @company,
      employee: employee,
      day_of_week: Time.current.wday,
      start_time: "00:00",
      end_time: "23:59",
      available: true,
      schedule_type: "recurring"
    )

    sign_in create(:user, role: :client)
    get company_public_path(@company)

    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(I18n.t("company_public.next_slot.cta"))
    assert_includes response.body, "data-tracking-event=\"priority_slot_click\""
  end

  test "GET show expose un schema LocalBusiness valide" do
    employee = create(:employee, company: @company)
    create(:schedule,
      company: @company,
      employee: employee,
      day_of_week: 1,
      start_time: "09:00",
      end_time: "18:00",
      available: true,
      schedule_type: "recurring")

    get company_public_path(@company)

    assert_response :success

    schema_match = response.body.match(/<script type="application\/ld\+json">\s*(\{.*?\})\s*<\/script>/m)
    assert schema_match.present?, "JSON-LD script should be present"

    payload = JSON.parse(schema_match[1])
    assert_equal "https://schema.org", payload["@context"]
    assert_equal "LocalBusiness", payload["@type"]
    assert_equal @company.name, payload["name"]
    assert_equal @company.address, payload.dig("address", "streetAddress")
    assert_equal @company.city, payload.dig("address", "addressLocality")
    assert_equal @company.zip_code, payload.dig("address", "postalCode")
    assert_equal "FR", payload.dig("address", "addressCountry")
    assert payload["openingHoursSpecification"].is_a?(Array)
    assert payload["openingHoursSpecification"].any? do |item|
      item["dayOfWeek"] == "https://schema.org/Monday" && item["opens"] == "09:00" && item["closes"] == "18:00"
    end
  end

  test "GET show inclut aggregateRating quand des avis publies existent" do
    appointment = create(:appointment, company: @company, service_type: @company.service_types.first)
    create(:review, :submitted, company: @company, appointment: appointment, rating: 5)

    get company_public_path(@company)

    assert_response :success

    schema_match = response.body.match(/<script type="application\/ld\+json">\s*(\{.*?\})\s*<\/script>/m)
    assert schema_match.present?, "JSON-LD script should be present"

    payload = JSON.parse(schema_match[1])
    assert_equal "AggregateRating", payload.dig("aggregateRating", "@type")
    assert_equal 5.0, payload.dig("aggregateRating", "ratingValue").to_f
    assert_equal 1, payload.dig("aggregateRating", "reviewCount")
  end

  test "GET show sante affiche les informations essentielles de reassurance" do
    @company.update!(
      professional_category: :healthcare_professional,
      health_specialty: "Dermatologie",
      convention_sector: :sector_1,
      teleconsultation_enabled: true,
      accessibility_info: "Acces PMR et parking public",
      practical_info: "Carte Vitale et ordonnances conseillees",
      cancellation_policy: "Annulation gratuite jusqu'a 24h avant"
    )

    get company_public_path(@company)

    assert_response :success
    assert_includes response.body, "Informations essentielles"
    assert_includes response.body, "Acces PMR et parking public"
    assert_includes response.body, "Modalites d'annulation"
  end
end
