require "active_support"
require "active_support/testing/autorun"
require "action_controller"
require "action_view"
require "action_view/test_case"
require "capybara/minitest"

require "nice_partials"

class NicePartials::Test < ActionView::TestCase
  include Capybara::Minitest::Assertions

  TestController.view_paths << "test/fixtures"

  private

  def page
    @page ||= Capybara.string(rendered)
  end

  def assert_rendered(matcher)
    assert_match matcher, rendered
  end
end
