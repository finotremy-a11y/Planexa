source "https://rubygems.org"

ruby "3.4.2"

# ── Core ──────────────────────────────────────────────────────────────────────
gem "rails", "~> 8.0.4"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# ── Frontend ──────────────────────────────────────────────────────────────────
gem "propshaft"           # Asset pipeline Rails 8
gem "turbo-rails"         # Hotwire Turbo
gem "stimulus-rails"      # Hotwire Stimulus
gem "importmap-rails"     # JS sans bundler

# ── Auth & Autorisations ──────────────────────────────────────────────────────
gem "devise"              # Authentification
gem "pundit"              # Autorisations par policy

# ── Paiements ─────────────────────────────────────────────────────────────────
gem "stripe", "~> 18.0"   # Stripe Billing + Connect

# ── Emails ────────────────────────────────────────────────────────────────────
gem "resend", "~> 0.10"   # Resend API pour emails transactionnels

# ── Jobs & Cache ──────────────────────────────────────────────────────────────
gem "sidekiq", "~> 7.0"   # Background jobs
gem "redis", "~> 5.0"     # Queue Sidekiq + cache
gem "solid_cache"          # Required by :solid_cache_store in production
gem "solid_cable"          # Required by Action Cable adapter :solid_cable in production

# ── Fichiers & Images ─────────────────────────────────────────────────────────
gem "cloudinary", "~> 2.0"        # Upload images
gem "activestorage-cloudinary-service"

# ── Recherche & Filtres ───────────────────────────────────────────────────────
gem "ransack"             # Filtres dynamiques
gem "pagy", "~> 43.4"     # Pagination

# ── Monitoring ────────────────────────────────────────────────────────────────
gem "sentry-ruby"             # Monitoring erreurs production
gem "sentry-rails"
gem "sentry-sidekiq"          # Erreurs dans les jobs Sidekiq

# ── SEO ───────────────────────────────────────────────────────────────────────
gem "sitemap_generator"       # Génération automatique sitemap.xml

# ── Utilitaires ───────────────────────────────────────────────────────────────
gem "money-rails", "~> 1.15"  # Gestion montants en centimes
gem "whenever", require: false  # Cron jobs
gem "twilio-ruby", "~> 7.0"    # SMS reminders
gem "chartkick"                 # Graphiques analytiques
gem "groupdate"                 # Groupement temporel ActiveRecord
gem "rack-cors"                 # CORS pour le widget embarquable
gem "prawn",       "~> 2.5"    # Génération PDF factures
gem "prawn-table", "~> 0.2"    # Tableaux Prawn pour les lignes de facture
gem "web-push", "~> 2.1"       # Notifications push natives (PWA)
gem "rqrcode", "~> 3.1"        # QR code imprimable pour la fiche publique/widget
gem "dotenv-rails", groups: [ :development, :test ]

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rails",         require: false
  gem "rubocop-performance",   require: false
  gem "bullet"
  gem "letter_opener"    # Preview emails en dev
  gem "brakeman",        require: false
end

group :test do
  gem "simplecov", require: false
  gem "minitest-reporters"
  gem "mocha"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
  gem "rails-controller-testing"
  gem "capybara"
  gem "selenium-webdriver"
end

gem "rack-attack"             # Rate limiting & throttling
gem "connection_pool", "~> 2.4"
