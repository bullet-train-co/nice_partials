require "test_helper"

class NicePartials::PartialTest < NicePartials::Test
  class Component
    def initialize(key)
      @key = key
    end

    def render_in(view_context)
      "component render_in #{@key}"
    end
  end

  class LinkComponent < ViewComponent::Base
    def initialize(name)
      @name = name
    end

    def call
      link_to "view_component.link_to", "example.com/#{@name}"
    end
  end

  test "appending content types consecutively" do
    partial = new_partial
    partial.body "some content"

    partial.body new_partial.body.tap { _1.write("content from another partial") }

    partial.body.link_to "Document", "document_url"

    partial.body Component.new(:plain)
    partial.body { Component.new(:from_block) }

    partial.body LinkComponent.new("nice_partials")
    partial.body { LinkComponent.new("nice_partials") }

    partial.body { _1 << ", appended to" }
    partial.body.yield "yielded content"

    assert_equal <<~OUTPUT.gsub("\n", ""), partial.body.to_s
      some content
      content from another partial
      <a href="document_url">Document</a>
      component render_in plain
      component render_in from_block
      <a href="example.com/nice_partials">view_component.link_to</a>
      <a href="example.com/nice_partials">view_component.link_to</a>
      yielded content, appended to
    OUTPUT
  end

  test "tag proxy with options" do
    partial = new_partial
    partial.title "content", class: "post-title"

    assert_equal "post-title",          partial.title.options[:class]
    assert_equal %(class="post-title"), partial.title.options.to_s

    assert_equal %(<p class="post-title">content</p>),   partial.title.p
    assert_equal %(<h2 class="post-title">content</h2>), partial.title.h2

    unless defined?(AttributesAndTokenLists)
      assert_equal %(<h2 class="">content</h2>),                 partial.title.h2(class: { "text-m4": false })
      assert_equal %(<h2 class="text-m4">contentaddendum</h2>),  partial.title.h2("addendum", class: "text-m4")
      assert_equal %(<h2 class="some-class">contentblabla</h2>), partial.title.h2("blabla", class: "some-class")
    end
  end

  private

  def new_partial
    NicePartials::Partial.new view
  end
end
