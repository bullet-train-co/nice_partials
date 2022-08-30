require "test_helper"

class NicePartials::PartialTest < ActiveSupport::TestCase
  class StubbedViewContext < ActionView::Base
    def initialize
    end

    def capture(*arguments)
      yield(*arguments)
    end
  end

  class Component
    def initialize(key)
      @key = key
    end

    def render_in(view_context)
      "component render_in #{@key}"
    end
  end

  test "appending content types consecutively" do
    partial = new_partial
    partial.body "some content"

    partial.body Component.new(:plain)
    partial.body { Component.new(:from_block) }

    partial.body { _1 << ", appended to" }
    partial.body.yield "yielded content"

    assert_equal <<~OUTPUT.gsub("\n", ""), partial.body.to_s
      some content
      component render_in plain
      component render_in from_block
      yielded content, appended to
    OUTPUT
  end

  private

  def new_partial
    NicePartials::Partial.new StubbedViewContext.new
  end
end
