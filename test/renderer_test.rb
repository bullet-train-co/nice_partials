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

  test "explicit yield without any arguments auto-captures passed block" do
    render "yields/plain" do |partial, auto_capture_shouldnt_pass_extra_argument|
      assert_kind_of NicePartials::Partial, partial
      assert_nil auto_capture_shouldnt_pass_extra_argument
    end
  end

  test "explicit yield with symbol auto-captures passed block" do
    render "yields/symbol" do |partial, auto_capture_shouldnt_pass_extra_argument|
      assert_kind_of NicePartials::Partial, partial
      assert_nil auto_capture_shouldnt_pass_extra_argument
    end
  end

  test "explicit yield with object won't auto-capture but make partial available in capture" do
    render "yields/object" do |object, partial|
      assert_equal Hash.new(custom_key: :custom_value), object
      assert_kind_of NicePartials::Partial, partial
    end
  end

  test "explicit yield without any arguments with nesting" do
    render "yields/plain_nested" do
      tag.span "Output in outer partial through yield"
    end

    assert_rendered "<span>Output in outer partial through yield</span>"
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
