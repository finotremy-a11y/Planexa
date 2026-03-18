require "application_system_test_case"

class CompanySettingsTest < ApplicationSystemTestCase
  setup do
    @user    = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user
  end

  test "peut modifier les réglages et les sauvegarder" do
    visit company_settings_path
    assert_text "Réglages"

    choose "Gestion privée"
    choose "Assignation manuelle"
    click_on "Sauvegarder les réglages"

    assert_text "Réglages sauvegardés"
    assert @company.setting.reload.booking_private?
    assert @company.setting.assignment_manual?
  end
end
