require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "issue! stores digest and returns plaintext token" do
    company = create(:company)

    token, plaintext = ApiToken.issue!(
      company: company,
      name: "Zapier",
      scopes: %w[read:appointments write:appointments]
    )

    assert token.persisted?
    assert plaintext.start_with?(ApiToken::TOKEN_PREFIX)
    assert_equal ApiToken.digest(plaintext), token.token_digest
    assert_includes token.scopes, "read:appointments"
  end

  test "authenticate finds token by plaintext and updates last_used_at" do
    company = create(:company)
    token, plaintext = ApiToken.issue!(company: company, name: "CRM")

    authenticated = ApiToken.authenticate(plaintext)

    assert_equal token.id, authenticated.id
    assert authenticated.last_used_at.present?
  end

  test "expired token is not active" do
    company = create(:company)
    token = create(:api_token, company: company, expires_at: 1.day.ago)

    assert_not ApiToken.active.exists?(id: token.id)
  end
end
