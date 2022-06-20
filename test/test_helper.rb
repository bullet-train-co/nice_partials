require "active_support"
require "active_support/testing/autorun"
require "action_controller"
require "action_view"
require "nice_partials"

FIXTURE_LOAD_PATH = File.expand_path("fixtures", __dir__)

class NicePartials::Test < ActiveSupport::TestCase
  # from actionview/render_test
  class TestController < ActionController::Base
  end

  def setup_view(paths)
    @assigns = { secret: "in the sauce" }

    @view = Class.new(ActionView::Base.with_empty_template_cache) do
      def view_cache_dependencies; []; end

      def combined_fragment_cache_key(key)
        [:views, key]
      end
    end.with_view_paths(paths, @assigns)

    controller = TestController.new
    controller.perform_caching = true
    controller.cache_store = :memory_store
    @view.controller = controller

    @controller_view = controller.view_context_class.with_empty_template_cache.new(
      controller.lookup_context,
      controller.view_assigns,
      controller)
  end

  setup do
    ActionView::LookupContext::DetailsKey.clear
    path = ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH)
    view_paths = ActionView::PathSet.new([path])
    assert_equal ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH), view_paths.first
    setup_view(view_paths)
  end

  teardown do
    ActionController::Base.view_paths.map(&:clear_cache)
  end
end
