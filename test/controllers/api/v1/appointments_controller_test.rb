require "test_helper"

class Api::V1::AppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = create(:company)
    @service_type = create(:service_type, company: @company)
    @employee = create(:employee, company: @company)
    # Keep employee available for API-created appointments in all weekdays.
    (0..6).each do |day|
      create(:schedule,
        company: @company,
        employee: @employee,
        day_of_week: day,
        start_time: "00:00",
        end_time: "23:59",
        available: true,
        schedule_type: "recurring")
    end
    @client = create(:user, role: :client)
    @appointment = create(:appointment,
      company: @company,
      service_type: @service_type,
      employee: @employee,
      client_user: @client)

    _, @read_token = ApiToken.issue!(
      company: @company,
      name: "Read token",
      scopes: %w[read:appointments]
    )

    _, @write_token = ApiToken.issue!(
      company: @company,
      name: "Write token",
      scopes: %w[write:appointments]
    )
  end

  test "rejects request without bearer token" do
    get "/api/v1/appointments"
    assert_response :unauthorized
  end

  test "lists appointments with read scope" do
    get "/api/v1/appointments", headers: auth_header(@read_token)

    assert_response :success
    body = JSON.parse(response.body)
    assert body["data"].is_a?(Array)
    assert_equal @appointment.id, body["data"].first["id"]
  end

  test "forbids create without write scope" do
    post "/api/v1/appointments",
      params: {
        appointment: {
          service_type_id: @service_type.id,
          employee_id: @employee.id,
          client_user_id: @client.id,
          scheduled_at: 2.days.from_now.iso8601,
          duration_minutes: 60
        }
      },
      headers: auth_header(@read_token),
      as: :json

    assert_response :forbidden
  end

  test "creates appointment with write scope" do
    assert_difference "Appointment.count", 1 do
      post "/api/v1/appointments",
        params: {
          appointment: {
            service_type_id: @service_type.id,
            employee_id: @employee.id,
            client_user_id: @client.id,
            scheduled_at: 3.days.from_now.iso8601,
            duration_minutes: 45,
            client_notes: "API booking"
          }
        },
        headers: auth_header(@write_token),
        as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "API booking", body.dig("data", "client_notes")
  end

  private

  def auth_header(token)
    {
      "Authorization" => "Bearer #{token}"
    }
  end
end
