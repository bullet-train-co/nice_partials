require "active_support"
require "active_support/testing/autorun"
require "action_controller"
require "action_view"
require "action_view/test_case"

require "nice_partials"

require "debug"

class NicePartials::Test < ActionView::TestCase
  TestController.view_paths << "test/fixtures"

  private

  def assert_rendered(matcher)
    assert_match matcher, rendered
  end
end
