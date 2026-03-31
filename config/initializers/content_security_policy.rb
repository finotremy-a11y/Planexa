# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :https, :data, "https://res.cloudinary.com"
    policy.object_src  :none
    policy.script_src  :self, :https,
                       "https://js.stripe.com",
                       "https://fonts.googleapis.com"
    policy.style_src   :self, :https, :unsafe_inline,
                       "https://fonts.googleapis.com"
    policy.frame_src   "https://js.stripe.com"
    policy.connect_src :self, :https,
                       "https://api.stripe.com",
                       "https://sentry.io",
                       "https://*.ingest.sentry.io"
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  config.content_security_policy_report_only = false
end
