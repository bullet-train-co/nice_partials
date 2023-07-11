ENV["RAILS_ENV"] = "test"
require "rails"
require "rails/test_help"

class TestApp < Rails::Application
  config.root = __dir__
  config.hosts << "example.org"
  secrets.secret_key_base = "secret_key_base"
end

require "capybara/minitest"
require "view_component"
require "nice_partials"

# Ensure we assign the default configs, so `view_component_path` is set.
ViewComponent::Base.config = ViewComponent::Config.new

class NicePartials::Test < ActionView::TestCase
  include Capybara::Minitest::Assertions

  TestController.prepend_view_path "test/fixtures"
  TestController.prepend_view_path "test/fixtures/(special)"

  private

  def page
    @page ||= Capybara.string(rendered)
  end
end

module BRB; end
module BRB::Sigils
  @values = {}

  def self.gsub!(source)
    source.gsub!(/\\(#{@values.keys.join("|")})=?((?:\.\w+)+|\((?:.*?)\))/) { "<%= #{@values[$1].sub('\2', $2)} %>" }
  end

  def self.register(key, replacer)
    @values[key.to_s] = replacer
  end

  register :t, 't "\2"'
  register :class, %s(class="\= class_names(\1)")
  register :attributes, 'tag.attributes(\1)'
  register :data, 'tag.attributes(data: \1)'
end

class BRB::Erubi < ::ActionView::Template::Handlers::ERB::Erubi
  # DEFAULT_REGEXP = /<%(={1,2}|-|\#|%)?(.*?)([-=])?%>([ \t]*\r?\n)?/m
  # DEFAULT_REGEXP = /<%(={1,2}|-|\#|%)?(.*?)([-=])?%>([ \t]*\r?\n)?/m

  def initialize(input, ...)
    old_input = input.dup
    if BRB::Sigils.gsub!(input)
      puts ["sigils", old_input, input] unless input.include?("clobbering")
    end

    if input.gsub!(/^\\\r?\n(.*?)^\\\r?\n/m, "<%\n\\1%>\n")
      puts ["group", old_input, input] unless input.include?("clobbering")
    end

    if input.gsub!(/(?<!\/)\\(.*?)(\<\/|[ \t]*\r?\n)/, '<%\1%>\2')
      puts ["line", old_input, input] unless input.include?("clobbering")
    end
    super
  end
end

ActionView::Template::Handlers::ERB.erb_implementation = BRB::Erubi
