require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 800 ]

  def setup
    chrome_available = system("which google-chrome > /dev/null 2>&1") ||
                       system("which chromium > /dev/null 2>&1") ||
                       system("which chromium-browser > /dev/null 2>&1")
    skip "Chrome/Chromium not installed — install chromium-browser to run system tests" unless chrome_available
    super
  end
end
