require "test_helper"

class RendererTest < NicePartials::Test
  test "render basic nice partial" do
    render("basic") { |p| p.content_for :message, "hello from nice partials" }

    assert_rendered "hello from nice partials"
  end

  test "render nice partial in card template" do
    render(template: "card_test")

    assert_rendered "Some Title"
    assert_rendered "Lorem Ipsum"
    assert_rendered "https://example.com/image.jpg"
  end

  test "output_buffer captures content not written via yield/content_for" do
    nice_partial = nil
    render "basic" do |p|
      nice_partial = p
      p.content_for :message, "hello from nice partials"
      "Some extra content"
    end

    assert_rendered "hello from nice partials"
    assert_equal "Some extra content", nice_partial.output_buffer
  end

  test "doesn't clobber Kernel.p" do
    assert_output "\"it's clobbering time\"\n" do
      render("clobberer") { |p| p.content_for :message, "hello from nice partials" }
    end

    assert_rendered "hello from nice partials"
  end

  test "deprecates top-level access through p method" do
    assert_deprecated /p is deprecated and will be removed from nice_partials \d/, NicePartials::DEPRECATOR do
      assert_output "\"it's clobbering time\"\n" do
        render("clobberer") { |p| p.content_for :message, "hello from nice partials" }
      end
    end
  end
end
