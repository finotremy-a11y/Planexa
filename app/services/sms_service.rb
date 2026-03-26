# frozen_string_literal: true

# Wrapper Twilio pour l'envoi de SMS.
# Configure via ENV: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER
class SmsService
  # Envoie un SMS. Retourne true en cas de succès, false sinon.
  def self.send(to:, body:)
    return false unless credentials_present?

    to_e164 = normalize_phone(to)
    return false if to_e164.nil?

    client = Twilio::REST::Client.new(
      ENV["TWILIO_ACCOUNT_SID"],
      ENV["TWILIO_AUTH_TOKEN"]
    )

    client.messages.create(
      from: ENV["TWILIO_PHONE_NUMBER"],
      to:   to_e164,
      body: body
    )
    true
  rescue Twilio::REST::RestError => e
    Rails.logger.error("[SmsService] Twilio error: #{e.message}")
    false
  rescue StandardError => e
    Rails.logger.error("[SmsService] SMS send failed: #{e.message}")
    false
  end

  # Normalise un numéro de téléphone vers le format E.164 (+33...)
  # Retourne nil si le format est invalide.
  def self.normalize_phone(phone)
    return nil if phone.blank?

    digits = phone.gsub(/[\s\-\(\)\.]/, "")

    # Already E.164
    return digits if digits.match?(/\A\+\d{7,15}\z/)

    # French number starting with 0 → strip and prepend +33
    if digits.match?(/\A0[0-9]{9}\z/)
      return "+33#{digits[1..]}"
    end

    nil
  end

  # Retourne true si les trois variables d'environnement Twilio sont présentes.
  # Déclaré comme méthode de classe pour permettre le stubbing en tests.
  def self.credentials_present?
    ENV["TWILIO_ACCOUNT_SID"].present? &&
      ENV["TWILIO_AUTH_TOKEN"].present? &&
      ENV["TWILIO_PHONE_NUMBER"].present?
  end
end
