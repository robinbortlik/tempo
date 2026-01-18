require 'capybara/rspec'
require 'capybara/playwright'

# Configure Capybara for system tests
Capybara.default_max_wait_time = 5

# Register Playwright driver (headless)
Capybara.register_driver :playwright_headless do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: true
  )
end

# Register Playwright driver (visible browser for debugging)
Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: false
  )
end

# Use rack_test by default, Playwright for JS tests
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :playwright_headless

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright_headless
  end

  config.before(:each, type: :system, js: true) do
    driven_by :playwright_headless
  end
end
