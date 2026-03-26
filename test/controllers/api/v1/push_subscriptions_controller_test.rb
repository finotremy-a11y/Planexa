require "test_helper"

class Api::V1::PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, role: :client)
    @company_admin = create(:user, :company_admin)
    @company = create(:company, user: @company_admin)
    create(:appointment, company: @company, client_user: @user, service_type: create(:service_type, company: @company))

    sign_in @user
  end

  test "returns vapid key" do
    get "/api/v1/push_subscriptions/vapid_key"

    assert_response :success
    body = JSON.parse(response.body)
    assert body["vapidPublicKey"].present?
  end

  test "creates push subscription" do
    assert_difference "PushSubscription.count", 1 do
      post "/api/v1/push_subscriptions",
        params: {
          subscription: {
            endpoint: "https://example.org/push/abc",
            auth: "auth-key",
            p256dh: "p256dh-key"
          }
        }
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "success", body["status"]
  end

  test "rejects when user is signed out" do
    sign_out @user

    post "/api/v1/push_subscriptions", params: {
      subscription: {
        endpoint: "https://example.org/push/abc",
        auth: "auth-key",
        p256dh: "p256dh-key"
      }
    }

    assert_response :found
  end
end
