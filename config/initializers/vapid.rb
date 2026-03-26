# config/initializers/vapid.rb
# Configuration VAPID pour les notifications push natives

# Générer une paire de clés VAPID:
#   require 'web_push'
#   vapid_key = WebPush.generate_key
#   puts "Public key: #{vapid_key[:public_key]}"
#   puts "Private key: #{vapid_key[:private_key]}"

vapid_key_public = ENV.fetch('VAPID_PUBLIC_KEY', nil)
vapid_key_private = ENV.fetch('VAPID_PRIVATE_KEY', nil)

# En dev/test, fallback non bloquant pour eviter de casser le boot
if !Rails.env.production? && (vapid_key_public.blank? || vapid_key_private.blank?)
  vapid_key_public ||= "dev_vapid_public_key"
  vapid_key_private ||= "dev_vapid_private_key"
  Rails.logger.warn("VAPID keys are missing; using development fallback values.")
end

# Valider que les clés VAPID existent en production
if Rails.env.production?
  raise "VAPID_PUBLIC_KEY is required in production" if vapid_key_public.blank?
  raise "VAPID_PRIVATE_KEY is required in production" if vapid_key_private.blank?
end

# Stocker dans Rails.configuration pour accès global
Rails.configuration.vapid = {
  public_key: vapid_key_public,
  private_key: vapid_key_private,
  subject: ENV.fetch('VAPID_SUBJECT', "mailto:support@planifypro.app")
}
