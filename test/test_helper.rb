require "active_support"
require "active_support/testing/autorun"
require "action_controller"
require "action_view"
require "action_view/test_case"
require "capybara/minitest"

ENV["RAILS_ENV"] = "test"
require "rails"
require "rails/test_help"

class TestApp < Rails::Application
  config.root = __dir__
  config.hosts << "example.org"
  secrets.secret_key_base = "secret_key_base"
end

require "view_component"
require "nice_partials"

class NicePartials::Test < ActionView::TestCase
  include Capybara::Minitest::Assertions

  TestController.view_paths << "test/fixtures"

  private

  def page
    @page ||= Capybara.string(rendered)
  end
end
