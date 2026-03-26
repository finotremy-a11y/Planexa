require "test_helper"

class ApiWebhookTest < ActiveSupport::TestCase
  test "is valid with supported events" do
    webhook = build(:api_webhook, events: ["appointment.created", "payment.succeeded"])
    assert webhook.valid?
  end

  test "is invalid with unsupported events" do
    webhook = build(:api_webhook, events: ["foo.bar"])

    assert_not webhook.valid?
    assert_includes webhook.errors[:events].join(" "), "non support"
  end

  test "signature_for returns deterministic hmac" do
    webhook = build(:api_webhook, secret: "abc123")

    sig1 = webhook.signature_for("{\"x\":1}")
    sig2 = webhook.signature_for("{\"x\":1}")

    assert_equal sig1, sig2
    assert sig1.present?
  end
end
