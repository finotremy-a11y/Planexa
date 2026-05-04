require "application_system_test_case"

class MobileResponsiveTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    @service_type = create(:service_type, company: @company, name: "Consultation mobile")
    @employee = create(:employee, company: @company, first_name: "Alice", last_name: "Martin")
    @appointment = create(
      :appointment,
      company: @company,
      service_type: @service_type,
      client_user: create(:user, first_name: "Nina", last_name: "Durand")
    )
    sign_in @user
  end

  test "dashboard remains within mobile viewport sizes" do
    with_mobile_viewports do |_name, width, height|
      resize_to_viewport(width, height)
      visit company_root_path

      assert_selector ".page-header h1", text: /Bonjour/
      assert_no_horizontal_scroll
    end
  end

  test "public mobile navbar shows burger control" do
    visit root_path
    resize_to_viewport(*MOBILE_VIEWPORTS[:iphone])

    assert_selector "#navbarHamburger", visible: true
    assert_selector "#navbarLinks", visible: :all
    assert_no_horizontal_scroll
  end

  test "calendar stays contained on small phones" do
    resize_to_viewport(*MOBILE_VIEWPORTS[:small_phone])
    visit calendar_company_appointments_path

    assert_selector ".calendar-grid"
    assert_selector ".calendar-event-count", minimum: 1
    assert_no_horizontal_scroll
  end

  test "new and edit appointment forms stay usable on mobile" do
    [ new_company_appointment_path, edit_company_appointment_path(@appointment) ].each do |path|
      resize_to_viewport(*MOBILE_VIEWPORTS[:iphone])
      visit path

      assert_selector ".appointment-form"
      assert_selector ".responsive-form-actions"
      assert_no_horizontal_scroll
    end
  end

  test "settings remain usable on mobile" do
    resize_to_viewport(*MOBILE_VIEWPORTS[:iphone_plus])
    visit company_settings_path

    assert_selector "h1", text: /Réglages|Reglages/
    assert_selector "form"
    assert_no_horizontal_scroll
  end

  test "onboarding page remains usable on mobile" do
    user_without_company = create(:user, :company_admin)
    sign_in user_without_company

    resize_to_viewport(*MOBILE_VIEWPORTS[:iphone_plus])
    visit company_onboarding_path

    assert_text "Créez votre profil entreprise"
    assert_no_horizontal_scroll
  end

  test "public contact form stays usable on mobile" do
    visit contact_path
    resize_to_viewport(*MOBILE_VIEWPORTS[:iphone])

    assert_selector "form"
    assert_selector "input[name='name']"
    assert_selector "input[name='email']"
    assert_selector "textarea[name='message']"
    assert_no_horizontal_scroll
  end
end
