require_relative "./test_helper"

class PartialRendererTest < ActiveSupport::TestCase
  # from actionview/render_test
  class TestController < ActionController::Base
  end
 
  def setup_view(paths)
    ActionView::Base.include(NicePartials::Helper)

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

  def setup
    ActionView::LookupContext::DetailsKey.clear
    path = ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH)
    view_paths = ActionView::PathSet.new([path])
    assert_equal ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH), view_paths.first
    setup_view(view_paths)
  end

  def teardown
    ActionController::Base.view_paths.map(&:clear_cache)
  end

  test "render basic nice partial" do
    assert_equal "hello from nice partials", @view.render(partial: "basic").squish
  end
end
