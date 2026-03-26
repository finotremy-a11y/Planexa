require "test_helper"

class SmsServiceTest < ActiveSupport::TestCase
  # ── normalize_phone ────────────────────────────────────────────────────────

  test "normalise un numéro français format 06..." do
    assert_equal "+33612345678", SmsService.normalize_phone("0612345678")
  end

  test "normalise un numéro avec espaces" do
    assert_equal "+33612345678", SmsService.normalize_phone("06 12 34 56 78")
  end

  test "normalise un numéro avec tirets" do
    assert_equal "+33612345678", SmsService.normalize_phone("06-12-34-56-78")
  end

  test "retourne nil pour un numéro vide" do
    assert_nil SmsService.normalize_phone(nil)
    assert_nil SmsService.normalize_phone("")
  end

  test "retourne nil pour un numéro invalide" do
    assert_nil SmsService.normalize_phone("12345")
    assert_nil SmsService.normalize_phone("abcd")
  end

  test "préserve un numéro déjà en E.164" do
    assert_equal "+33612345678", SmsService.normalize_phone("+33612345678")
  end

  # ── send — sans credentials ────────────────────────────────────────────────

  test "retourne false si les credentials Twilio sont absents" do
    SmsService.stubs(:credentials_present?).returns(false)
    result = SmsService.send(to: "+33612345678", body: "Test SMS")
    assert_equal false, result
  end

  # ── send — avec credentials mockés ────────────────────────────────────────

  test "envoie un SMS si les credentials sont présents et numéro valide" do
    SmsService.stubs(:credentials_present?).returns(true)
    mock_client  = mock
    mock_messages = mock
    mock_client.stubs(:messages).returns(mock_messages)
    mock_messages.expects(:create).once.returns(true)
    Twilio::REST::Client.stubs(:new).returns(mock_client)

    result = SmsService.send(to: "0612345678", body: "Test")
    assert result
  end

  test "retourne false si le numéro est invalide même avec credentials" do
    SmsService.stubs(:credentials_present?).returns(true)
    result = SmsService.send(to: "invalid", body: "Test")
    assert_equal false, result
  end

  test "capture les erreurs Twilio sans lever d'exception" do
    SmsService.stubs(:credentials_present?).returns(true)
    mock_client   = mock
    mock_messages = mock
    mock_client.stubs(:messages).returns(mock_messages)
    mock_messages.stubs(:create).raises(StandardError, "Test error")
    Twilio::REST::Client.stubs(:new).returns(mock_client)

    result = nil
    assert_nothing_raised { result = SmsService.send(to: "0612345678", body: "Test") }
    assert_equal false, result
  end
end
