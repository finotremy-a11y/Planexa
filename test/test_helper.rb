require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_group "Controllers", "app/controllers"
  add_group "Models",      "app/models"
  add_group "Services",    "app/services"
  add_group "Jobs",        "app/jobs"
  add_group "Mailers",     "app/mailers"
  add_group "Policies",    "app/policies"
end

if (ENV["RAILS_ENV"].presence || "test") == "test"
  test_db_url = ENV["TEST_DATABASE_URL"].to_s
  primary_db_url = ENV["DATABASE_URL"].to_s
  same_db = test_db_url.present? && primary_db_url.present? && test_db_url == primary_db_url

  if ENV["ALLOW_TEST_ON_PRIMARY_DB"] != "1" && (test_db_url.blank? || same_db)
    abort <<~MSG
      Unsafe test database configuration detected.
      Set TEST_DATABASE_URL to an isolated database before running tests.
      If you intentionally want to run tests on the primary DB, set ALLOW_TEST_ON_PRIMARY_DB=1.
    MSG
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"
require "mocha/minitest"

Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new
# Only load factories from test/factories (not spec/factories)
FactoryBot.definition_file_paths = [ "test/factories" ]

# Allow DatabaseCleaner on Supabase (remote DB used as test DB)
DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation, { truncate_option: "CASCADE" }
# Nettoyage initial : garantit un état propre même après un run interrompu
DatabaseCleaner.clean_with(:truncation, truncate_option: "CASCADE")

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # Disable Rails fixtures (we use FactoryBot instead)
  self.use_transactional_tests = false

  setup    { DatabaseCleaner.start }
  teardown { DatabaseCleaner.clean }
end
