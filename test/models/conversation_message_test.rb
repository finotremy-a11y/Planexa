# frozen_string_literal: true

require "test_helper"
require "stringio"

class ConversationMessageTest < ActiveSupport::TestCase
  test "valide avec un body" do
    message = build(:conversation_message)
    assert message.valid?, message.errors.full_messages.inspect
  end

  test "invalide sans body ni photo" do
    message = build(:conversation_message, body: nil)
    assert_not message.valid?
    assert_includes message.errors.full_messages, "Le message ne peut pas etre vide"
  end

  test "valide avec photo sans body" do
    message = build(:conversation_message, body: nil)
    message.photos.attach(io: StringIO.new("fake-image-content"), filename: "photo.png", content_type: "image/png")

    assert message.valid?, message.errors.full_messages.inspect
  end

  test "invalide si sender hors conversation" do
    conversation = create(:conversation)
    outsider = create(:user)
    message = build(:conversation_message, conversation: conversation, sender: outsider)

    assert_not message.valid?
    assert_includes message.errors[:sender], "n'est pas autorise pour cette conversation"
  end
end
