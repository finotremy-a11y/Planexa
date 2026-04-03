require "test_helper"
require "base64"

class Company::ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PNG_1X1_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9sX8sXkAAAAASUVORK5CYII="

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_profile_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_profile_path
    assert_redirected_to root_path
  end

  # — Show —
  test "GET show retourne 200" do
    get company_profile_path
    assert_response :success
  end

  # — Edit —
  test "GET edit retourne 200" do
    get edit_company_profile_path
    assert_response :success
  end

  # — Update —
  test "PATCH update avec données valides met à jour le profil" do
    patch company_profile_path, params: {
      company: {
        name:        "Nouveau Nom SARL",
        city:        "Lyon",
        address:     "12 rue de la Paix",
        zip_code:    "69001",
        phone:       "0478000000",
        description: "Description mise à jour",
        website:     "https://example.com"
      }
    }
    assert_equal "Nouveau Nom SARL", @company.reload.name
    assert_equal "Lyon", @company.reload.city
    assert_redirected_to company_profile_path
  end

  test "PATCH update avec données invalides affiche le formulaire" do
    patch company_profile_path, params: {
      company: { name: "" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update en mode professionnel de sante persiste les champs specifiques" do
    patch company_profile_path, params: {
      company: {
        professional_category: "healthcare_professional",
        health_specialty: "Medecin generaliste",
        convention_sector: "sector_1",
        teleconsultation_enabled: "1",
        accessibility_info: "Acces PMR et ascenseur",
        practical_info: "Se presenter 10 minutes avant la consultation",
        cancellation_policy: "Annulation gratuite jusqu'a 24h"
      }
    }

    assert_redirected_to company_profile_path
    assert @company.reload.healthcare_professional?
    assert_equal "Medecin generaliste", @company.health_specialty
    assert_equal "sector_1", @company.convention_sector
    assert @company.teleconsultation_enabled?
    assert_equal "Acces PMR et ascenseur", @company.accessibility_info
    assert_equal "Se presenter 10 minutes avant la consultation", @company.practical_info
    assert_equal "Annulation gratuite jusqu'a 24h", @company.cancellation_policy
  end

  test "PATCH update refuse un profil sante sans specialite" do
    patch company_profile_path, params: {
      company: {
        professional_category: "healthcare_professional",
        health_specialty: "",
        convention_sector: "sector_2"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Specialite"
  end

  test "PATCH update ne peut pas modifier le profil d'une autre entreprise" do
    other_user    = create(:user, :company_admin)
    other_company = create(:company, user: other_user, name: "Autre Entreprise")
    # Connecté en tant que @user, tente de modifier other_company
    patch company_profile_path, params: {
      company: { name: "Hacked" }
    }
    # Le controller modifie @company (scopé à current_user), pas other_company
    assert_not_equal "Hacked", other_company.reload.name
  end

  test "PATCH update avec logo met a jour logo_public_id" do
    Tempfile.create(["company-logo", ".png"]) do |file|
      file.binmode
      file.write(Base64.decode64(PNG_1X1_BASE64))
      file.rewind

      uploaded_logo = Rack::Test::UploadedFile.new(file.path, "image/png")
      Cloudinary::Uploader.expects(:upload).once.returns({ "public_id" => "planexa/companies/logo_123" })

      patch company_profile_path, params: {
        company: {
          logo: uploaded_logo
        }
      }
    end

    assert_redirected_to company_profile_path
    assert_equal "planexa/companies/logo_123", @company.reload.logo_public_id
  end

  test "PATCH update avec remove_logo supprime le logo" do
    @company.update!(logo_public_id: "planexa/companies/existing_logo")

    patch company_profile_path, params: {
      company: {
        remove_logo: "1"
      }
    }

    assert_redirected_to company_profile_path
    assert_nil @company.reload.logo_public_id
  end
end
