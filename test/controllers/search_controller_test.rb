require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @company = create(:company, name: "Plomberie Lyon", city: "Lyon", status: :active)
    @company.company_setting.update!(booking_mode: :booking_public)
    create(:service_type, company: @company, name: "Plomberie")
  end

  test "GET index retourne 200" do
    get search_path
    assert_response :success
  end

  test "filtre par nom retourne la bonne entreprise" do
    get search_path, params: { name: "Plomberie" }
    assert_response :success
    assert_select "body", /Plomberie Lyon/
  end

  test "filtre par activité retourne la bonne entreprise" do
    get search_path, params: { activity: "Plomberie" }
    assert_response :success
    assert_select "body", /Plomberie Lyon/
  end

  test "entreprise privée n'apparaît pas dans les résultats" do
    private_company = create(:company, name: "Privée SA")
    private_company.company_setting.update!(booking_mode: :booking_private)
    get search_path, params: { name: "Privée" }
    assert_response :success
    assert_select "body", { text: /Privée SA/, count: 0 }
  end

  test "filtre urgent ne lève pas d'erreur" do
    get search_path, params: { urgent: "1" }
    assert_response :success
  end

  test "filtre par specialite medicale retourne les entreprises de sante correspondantes" do
    @company.update!(
      professional_category: :healthcare_professional,
      health_specialty: "Psychologie",
      convention_sector: :sector_1
    )

    other_company = create(:company, name: "Cabinet Osteo Lyon", city: "Lyon", status: :active)
    other_company.company_setting.update!(booking_mode: :booking_public)
    other_company.update!(
      professional_category: :healthcare_professional,
      health_specialty: "Osteopathie",
      convention_sector: :sector_2
    )

    get search_path, params: { specialty: "Psychologie" }

    assert_response :success
    assert_select "body", /Plomberie Lyon/
    assert_select "body", { text: /Cabinet Osteo Lyon/, count: 0 }
  end

  test "affiche le filtre de specialite dans le formulaire" do
    get search_path

    assert_response :success
    assert_select "select[name='specialty']"
    assert_select "option", text: /Psychologie/
    assert_select "option", text: /Plomberie/
    assert_select "option", text: /Barbier/
  end

  test "filtre par specialite non medicale via service retourne la bonne entreprise" do
    other_company = create(:company, name: "Cabinet Osteo Lyon", city: "Lyon", status: :active)
    other_company.company_setting.update!(booking_mode: :booking_public)
    other_company.update!(
      professional_category: :healthcare_professional,
      health_specialty: "Osteopathie",
      convention_sector: :sector_2
    )
    create(:service_type, company: other_company, name: "Consultation osteo")

    get search_path, params: { specialty: "Plomberie" }

    assert_response :success
    assert_select "body", /Plomberie Lyon/
    assert_select "body", { text: /Cabinet Osteo Lyon/, count: 0 }
  end

  test "landing SEO categorie x ville retourne 200" do
    get seo_search_landing_path(activity_slug: "plomberie", city_slug: "lyon")

    assert_response :success
    assert_select "h1", /Plomberie a Lyon/
    assert_select "link[rel='canonical'][href='http://www.example.com/recherche/plomberie/lyon']"
  end

  test "landing SEO filtre bien activite et ville" do
    other_city = create(:company, name: "Plomberie Paris", city: "Paris", status: :active)
    other_city.company_setting.update!(booking_mode: :booking_public)
    create(:service_type, company: other_city, name: "Plomberie")

    other_activity = create(:company, name: "Electricite Lyon", city: "Lyon", status: :active)
    other_activity.company_setting.update!(booking_mode: :booking_public)
    create(:service_type, company: other_activity, name: "Electricite")

    get seo_search_landing_path(activity_slug: "plomberie", city_slug: "lyon")

    assert_response :success
    assert_select "body", /Plomberie Lyon/
    assert_select "body", { text: /Plomberie Paris/, count: 0 }
    assert_select "body", { text: /Electricite Lyon/, count: 0 }
  end

  test "affiche la preuve sociale sur la carte de recherche" do
    appointment = create(:appointment, company: @company, service_type: @company.service_types.first)
    create(:review, :submitted, company: @company, appointment: appointment, rating: 4)

    get search_path, params: { activity: "Plomberie", city: "Lyon" }

    assert_response :success
    assert_select "body", /★\s*4\.0/
    assert_select "body", /1 avis/
  end

  test "affiche la preuve sociale sur la landing SEO" do
    appointment = create(:appointment, company: @company, service_type: @company.service_types.first)
    create(:review, :submitted, company: @company, appointment: appointment, rating: 5)

    get seo_search_landing_path(activity_slug: "plomberie", city_slug: "lyon")

    assert_response :success
    assert_select "body", /★\s*5\.0/
    assert_select "body", /1 avis/
  end
end
