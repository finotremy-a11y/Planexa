require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "guest can switch locale and see translated navigation" do
    get root_path
    assert_response :success

    patch locale_path(locale: :en), headers: { "HTTP_REFERER" => root_path }
    assert_redirected_to root_path

    follow_redirect!
    assert_includes response.body, "Search"
  end

  test "signed user locale is persisted in profile" do
    user = create(:user, locale: :fr)
    sign_in user

    patch locale_path(locale: :es), headers: { "HTTP_REFERER" => root_path }
    assert_redirected_to root_path

    assert_equal "es", user.reload.locale
  end

  test "unsupported locale falls back with alert" do
    patch locale_path(locale: :de), headers: { "HTTP_REFERER" => root_path }
    assert_redirected_to root_path

    follow_redirect!
    assert_includes response.body, I18n.t("locale.unsupported", locale: :fr)
  end
end
