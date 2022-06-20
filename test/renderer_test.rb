require "test_helper"

class RendererTest < NicePartials::Test
  test "render basic nice partial" do
    render("basic") { |p| p.content_for :message, "hello from nice partials" }

    assert_rendered "hello from nice partials"
  end

  test "render basic nice partial with custom name" do
    render("basic") { |p| p.message "hello from nice partials" }

    assert_rendered "hello from nice partials"
  end

  test "render nice partial in card template" do
    render(template: "card_test")

    assert_rendered "Some Title"
    assert_rendered "Lorem Ipsum"
    assert_rendered "https://example.com/image.jpg"
  end

  test "render nice partial card with options" do
    render("card_with_options")

    assert_select "span.some-class[data-controller='yup']"
  end
end
