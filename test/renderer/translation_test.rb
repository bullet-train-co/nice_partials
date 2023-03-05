require "test_helper"

module Renderer; end

class Renderer::TranslationTest < NicePartials::Test
  setup do
    I18n.backend.store_translations "en", translations: {
      translated: { message: "message" },
      nice_partials_translated: { message: "nice_partials" },
      nice_partials_translated_symbol: { message: "nice_partials" },
      t: { title: "title key content", header: "header key content" },
      special_nice_partials_translated: { message: "message content" }
    }
    I18n.backend.store_translations "en", custom: { key: "custom key content" }
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

  test "translations insert prefix from originating partial when translation key is a symbol" do
    render "translations/nice_partials_translated_symbol"

    assert_text "nice_partials"
  end

  test "translations key lookup handles special characters" do
    render "translations/special_nice_partials_translated"

    assert_text "message content"
  end

  test "translate method" do
    partial = nil
    render("translations/t") { partial = _1 }

    assert_equal "title key content",  partial.title.to_s
    assert_equal "header key content", partial.description.to_s
    assert_equal "custom key content", partial.byline.to_s
  end
end
