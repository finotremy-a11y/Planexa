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
DatabaseCleaner.strategy = :truncation

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
