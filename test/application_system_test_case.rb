require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 800 ]

  MOBILE_VIEWPORTS = {
    small_phone: [ 320, 800 ],
    iphone: [ 375, 812 ],
    iphone_plus: [ 414, 896 ],
    tablet: [ 768, 1024 ]
  }.freeze

  def setup
    chrome_available = system("which google-chrome > /dev/null 2>&1") ||
                       system("which chromium > /dev/null 2>&1") ||
                       system("which chromium-browser > /dev/null 2>&1")
    skip "Chrome/Chromium not installed — install chromium-browser to run system tests" unless chrome_available
    super
  end

  def resize_to_viewport(width, height)
    page.current_window.resize_to(width, height)
  end

  def assert_no_horizontal_scroll
    scroll_width = page.evaluate_script("Math.max(document.body.scrollWidth, document.documentElement.scrollWidth)")
    viewport_width = page.evaluate_script("window.innerWidth")

    assert_operator scroll_width, :<=, viewport_width,
      "Expected page to fit viewport, got scrollWidth=#{scroll_width} and innerWidth=#{viewport_width}"
  end

  def with_mobile_viewports(viewports = MOBILE_VIEWPORTS)
    viewports.each do |name, (width, height)|
      yield name, width, height
    end
  end
end
