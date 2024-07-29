ENV["RAILS_ENV"] = "test"
require "rails"
require "rails/test_help"

class TestApp < Rails::Application
  config.root = __dir__
  config.hosts << "example.org"
  credentials.secret_key_base = "secret_key_base"
end

require "capybara/minitest"
require "view_component"
require "nice_partials"

class NicePartials::Test < ActionView::TestCase
  include Capybara::Minitest::Assertions

  TestController.prepend_view_path "test/fixtures"
  TestController.prepend_view_path "test/fixtures/(special)"

  private

  def page
    @page ||= Capybara.string(rendered)
  end
end
