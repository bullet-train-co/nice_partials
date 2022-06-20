require "active_support"
require "active_support/testing/autorun"
require "action_controller"
require "action_view"
require "action_view/test_case"

require "nice_partials"

class NicePartials::Test < ActionView::TestCase
  TestController.view_paths << "test/fixtures"
end
