require "test_helper"

class Company::ServiceTypesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @service_type = create(:service_type, company: @company)
  end

  # — Authorization —
  test "redirige si non connecté" do
    sign_out @user
    get company_service_types_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_service_types_path
    assert_redirected_to root_path
  end

  # — Index —
  test "GET index retourne 200" do
    get company_service_types_path
    assert_response :success
  end

  # — New —
  test "GET new retourne 200" do
    get new_company_service_type_path
    assert_response :success
    assert_select "h2", text: "Assistant de creation rapide"
  end

  test "POST quick_create ajoute jusqu'a 3 templates" do
    assert_difference("ServiceType.count", 3) do
      post quick_create_company_service_types_path, params: {
        template_keys: [ "prestation_rapide", "prestation_standard", "prestation_premium" ]
      }
    end

    assert_redirected_to company_service_types_path
  end

  test "POST quick_create ignore les templates deja crees" do
    create(:service_type, company: @company, name: "Prestation rapide")

    assert_difference("ServiceType.count", 1) do
      post quick_create_company_service_types_path, params: {
        template_keys: [ "prestation_rapide", "prestation_standard" ]
      }
    end

    assert_redirected_to company_service_types_path
  end

  # — Create —
  test "POST create avec paramètres valides crée une prestation" do
    assert_difference("ServiceType.count", 1) do
      post company_service_types_path, params: {
        service_type: {
          name:             "Consultation",
          duration_minutes: 45,
          price_cents:      5000,
          active:           true
        }
      }
    end
    assert_redirected_to company_service_types_path
  end

  test "POST create enregistre la configuration d'acompte" do
    post company_service_types_path, params: {
      service_type: {
        name: "Intervention premium",
        duration_minutes: 60,
        price_cents: 10_000,
        deposit_kind: "deposit_percentage",
        deposit_value: 30,
        active: true
      }
    }

    created = ServiceType.order(:id).last
    assert_equal "deposit_percentage", created.deposit_kind
    assert_equal 30, created.deposit_value
  end

  test "POST create avec paramètres invalides affiche le formulaire" do
    assert_no_difference("ServiceType.count") do
      post company_service_types_path, params: {
        service_type: { name: "", duration_minutes: 0 }
      }
    end
    assert_response :unprocessable_entity
  end

  # — Edit —
  test "GET edit retourne 200" do
    get edit_company_service_type_path(@service_type)
    assert_response :success
  end

  test "GET edit retourne 404 pour une prestation d'une autre entreprise" do
    other_service = create(:service_type, company: create(:company))
    get edit_company_service_type_path(other_service)
    assert_response :not_found
  end

  # — Update —
  test "PATCH update avec données valides met à jour la prestation" do
    patch company_service_type_path(@service_type), params: {
      service_type: { name: "Nouveau nom", duration_minutes: 60, price_cents: 7500 }
    }
    assert_equal "Nouveau nom", @service_type.reload.name
    assert_redirected_to company_service_types_path
  end

  test "PATCH update avec données invalides affiche le formulaire" do
    patch company_service_type_path(@service_type), params: {
      service_type: { name: "", duration_minutes: -1 }
    }
    assert_response :unprocessable_entity
  end

  # — Destroy —
  test "DELETE destroy supprime la prestation" do
    # Créer une prestation sans RDV associé pour pouvoir la supprimer
    service = create(:service_type, company: @company)
    assert_difference("ServiceType.count", -1) do
      delete company_service_type_path(service)
    end
    assert_redirected_to company_service_types_path
  end

  # — Toggle active —
  test "PATCH toggle_active désactive une prestation active" do
    @service_type.update!(active: true)
    patch toggle_active_company_service_type_path(@service_type)
    assert_not @service_type.reload.active?
    assert_redirected_to company_service_types_path
  end

  test "PATCH toggle_active active une prestation inactive" do
    @service_type.update!(active: false)
    patch toggle_active_company_service_type_path(@service_type)
    assert @service_type.reload.active?
  end
end
