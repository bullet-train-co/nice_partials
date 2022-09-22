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
    partial.body.render Component.new(:render)
    partial.body { render Component.new(:from_block) }

    partial.body LinkComponent.new("nice_partials")
    partial.body { render LinkComponent.new("nice_partials") }

    partial.body { _1 << ", appended to" }
    partial.body.yield "yielded content"

    assert_equal <<~OUTPUT.gsub("\n", ""), partial.body.to_s
      some content
      content from another partial
      <a href="document_url">Document</a>
      component render_in plain
      component render_in render
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

    assert_equal %(<h2 class="">content</h2>),                 partial.title.h2(class: { "text-m4": false })
    assert_equal %(<h2 class="text-m4">contentaddendum</h2>),  partial.title.h2("addendum", class: "text-m4")
    assert_equal %(<h2 class="some-class">contentblabla</h2>), partial.title.h2("blabla", class: "some-class")
  end

  test "content_for returns content itself and not section object" do
    partial = new_partial
    partial.body "some content"

    assert_nil partial.content_for(:body, ", yet more"), "content_for must return nil when writing content"

    assert_equal "some content, yet more", partial.content_for(:body)
    assert_equal "some content, yet more", partial.body.to_s
  end

  test "passing section to another section writer" do
    outer_partial, inner_partial = new_partial, new_partial

    inner_partial.title outer_partial.title
    assert_empty inner_partial.title.to_s

    outer_partial.title "Hello there"
    inner_partial.title outer_partial.title
    assert_equal "Hello there", inner_partial.title.to_s
  end

  test "content_from with immediate contents" do
    outer_partial, inner_partial = new_partial, new_partial
    outer_partial.title "Hello there"

    inner_partial.content_from outer_partial, :title
    inner_partial.title ", and furthermore"

    assert_equal "Hello there, and furthermore", inner_partial.title.to_s
    assert_equal "Hello there", outer_partial.title.to_s
  end

  test "content_from with deferred contents" do
    outer_partial, inner_partial = new_partial, new_partial
    outer_partial.message { "Deferred" }

    inner_partial.content_from outer_partial, :message
    inner_partial.message { ", and furthermore" }

    assert_equal "Deferred, and furthermore", inner_partial.message.to_s
    assert_equal "Deferred", outer_partial.message.to_s
  end

  test "content_from with missing contents" do
    outer_partial, inner_partial = new_partial, new_partial

    inner_partial.content_from outer_partial, :title

    assert_empty inner_partial.title.to_s
    assert_empty outer_partial.title.to_s
  end

  test "content_from with renaming" do
    outer_partial, inner_partial = new_partial, new_partial
    outer_partial.title "Hello there"

    inner_partial.content_from outer_partial, title: :byline

    assert_equal "Hello there", inner_partial.byline.to_s
    assert_equal "Hello there", outer_partial.title.to_s
  end

  test "helpers don't leak to view" do
    partial = new_partial
    partial.helpers do
      def upcase(content)
        content.upcase
      end
    end

    assert_equal "YO", partial.upcase("yo")
    assert_not_respond_to view, :upcase
  end

  private

  def new_partial
    NicePartials::Partial.new view
  end
end
