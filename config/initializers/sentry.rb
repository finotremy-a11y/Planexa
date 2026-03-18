Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]

  # Capturer les erreurs uniquement en production
  config.enabled_environments = %w[production]

  # Traces de performance (10% des requêtes)
  config.traces_sample_rate = 0.1

  # Ne pas transmettre les données personnelles
  config.send_default_pii = false

  # Ignorer les erreurs non critiques (404, accès refusé, etc.)
  config.excluded_exceptions += [
    "ActionController::RoutingError",
    "ActiveRecord::RecordNotFound",
    "Pundit::NotAuthorizedError"
  ]
end
