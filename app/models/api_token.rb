class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "ppat_".freeze

  belongs_to :company

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.issue!(company:, name:, scopes: [], expires_at: nil)
    raw_token = "#{TOKEN_PREFIX}#{SecureRandom.hex(24)}"

    record = create!(
      company: company,
      name: name,
      token_digest: digest(raw_token),
      scopes: Array(scopes).map(&:to_s),
      expires_at: expires_at
    )

    [record, raw_token]
  end

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    token = active.find_by(token_digest: digest(raw_token))
    return nil unless token

    token.update_column(:last_used_at, Time.current)
    token
  end

  def allows_scope?(required_scope)
    scopes.include?(required_scope.to_s)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end
end
