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

# ── Fichiers & Images ─────────────────────────────────────────────────────────
gem "cloudinary", "~> 2.0"        # Upload images
gem "activestorage-cloudinary-service"

# ── Recherche & Filtres ───────────────────────────────────────────────────────
gem "ransack"             # Filtres dynamiques
gem "pagy", "~> 9.0"      # Pagination

# ── Utilitaires ───────────────────────────────────────────────────────────────
gem "money-rails", "~> 1.15"  # Gestion montants en centimes
gem "whenever", require: false  # Cron jobs
gem "dotenv-rails", groups: [:development, :test]

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails"
end

group :development do
  gem "web-console"
  gem "rubocop-rails-omakase", require: false
  gem "letter_opener"    # Preview emails en dev
end

group :test do
  gem "shoulda-matchers"
  gem "rails-controller-testing"
end

gem "connection_pool", "~> 2.4"
