require_relative "./test_helper"

class RendererTest < NicePartials::Test
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
