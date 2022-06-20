require_relative "./test_helper"

class RendererTest < ActiveSupport::TestCase
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

  test "render basic nice partial" do
    rendered = @view.render("basic") { |p| p.content_for :message, "hello from nice partials" }.squish

    assert_equal "hello from nice partials", rendered
  end

  test "render nice partial in card template" do
    rendered = @view.render(template: "card_test").squish

    assert_match "Some Title", rendered
    assert_match "Lorem Ipsum", rendered
    assert_match "https://example.com/image.jpg", rendered
  end
end
