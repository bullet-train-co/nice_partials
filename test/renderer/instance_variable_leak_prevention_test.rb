require "test_helper"

module Renderer; end

class Renderer::InstanceVariableLeakPreventionTest < NicePartials::Test
  setup { view.assign title: "ivar title" }

  test "instance variables won't leak into partial" do
    error = assert_raises ActionView::Template::Error do
      render "renderer/instance_variable_leak_prevention/with_ivar"
    end

    assert_empty rendered
    assert_equal "ivar title", view.instance_variable_get(:@title)
    assert_equal "undefined method `upcase' for nil:NilClass", error.message
  end

  test "local variables work" do
    render "renderer/instance_variable_leak_prevention/without_ivar", title: "local title"

    assert_text "LOCAL TITLE"
    assert_equal "ivar title", view.instance_variable_get(:@title)
  end
end
