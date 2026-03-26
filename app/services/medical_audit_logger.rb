class MedicalAuditLogger
  # Logs only for healthcare companies to avoid noisy generic traces.
  def self.log!(company:, user:, action:, record:, metadata: {})
    return unless company&.healthcare_professional?

    MedicalAuditLog.create!(
      company: company,
      user: user,
      action: action,
      record_type: record.class.name,
      record_id: record.id,
      metadata: metadata
    )
  end
end
