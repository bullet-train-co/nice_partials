require "test_helper"

module Renderer; end

class Renderer::TranslationTest < NicePartials::Test
  setup do
    I18n.backend.store_translations "en", { translations: {
      translated: { message: "message" },
      nice_partials_translated: { message: "nice_partials" }
    } }
  end

  teardown { I18n.reload! }

  test "clean translation render" do
    render "translations/translated"

    assert_text "message"
  end

  test "translations insert prefix from originating partial" do
    render "translations/nice_partials_translated"

    assert_text "nice_partials"
  end
end
