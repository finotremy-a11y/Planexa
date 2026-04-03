# frozen_string_literal: true

require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "valide avec company et client" do
    conversation = build(:conversation)
    assert conversation.valid?, conversation.errors.full_messages.inspect
  end

  test "invalide si client_user n'est pas un client" do
    company = create(:company)
    admin = create(:user, :company_admin)
    conversation = build(:conversation, company: company, client_user: admin)

    assert_not conversation.valid?
    assert_includes conversation.errors[:client_user], "doit etre un client"
  end

  test "unicite company/client" do
    conversation = create(:conversation)
    duplicate = build(:conversation, company: conversation.company, client_user: conversation.client_user)

    assert_not duplicate.valid?
  end
end
