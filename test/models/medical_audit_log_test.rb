require "test_helper"

class MedicalAuditLogTest < ActiveSupport::TestCase
  test "valide avec attributs minimaux" do
    log = build(:medical_audit_log)
    assert log.valid?
  end

  test "invalide sans action" do
    log = build(:medical_audit_log, action: nil)
    assert_not log.valid?
  end
end
