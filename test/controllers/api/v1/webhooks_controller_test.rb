require "test_helper"

class Api::V1::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = create(:company)
    _, @read_token = ApiToken.issue!(company: @company, name: "Read", scopes: %w[read:webhooks])
    _, @write_token = ApiToken.issue!(company: @company, name: "Write", scopes: %w[write:webhooks])
  end

  test "lists webhooks with read scope" do
    webhook = create(:api_webhook, company: @company)

    get "/api/v1/webhooks", headers: auth_header(@read_token)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal webhook.id, body.dig("data", 0, "id")
  end

  test "creates webhook with write scope" do
    assert_difference "ApiWebhook.count", 1 do
      post "/api/v1/webhooks",
        params: {
          webhook: {
            url: "https://example.com/hooks/dreamagenda",
            events: ["appointment.created", "appointment.cancelled"],
            active: true
          }
        },
        headers: auth_header(@write_token),
        as: :json
    end

    assert_response :created
  end

  test "rejects write with read-only token" do
    post "/api/v1/webhooks",
      params: {
        webhook: {
          url: "https://example.com/hooks/dreamagenda",
          events: ["appointment.created"]
        }
      },
      headers: auth_header(@read_token),
      as: :json

    assert_response :forbidden
  end

  private

  def auth_header(token)
    {
      "Authorization" => "Bearer #{token}"
    }
  end
end
