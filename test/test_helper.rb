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

# Here's BRB with preprocessing sigils. Sigils aim to make actions common in an HTML context easier to write.
# At template compile time the sigils are `gsub`'ed into their replacements.
#
# They follow this syntax, here `sigil_name` is the name of the Sigil:
#
#   \sigil_name # A sigil with no arguments
#   \sigil_name(< ruby expression >) # A sigil with arguments, must be called with ()
#
# Examples:
#
#   \class(active: post.active?) -> class="<%= class_names(active: post.active?) %>"
#   \attributes(post.options) -> <%= tag.attributes(post.options) %>
#   \p(post.options) -> <%= tag.attributes(post.options) %>
#   \data(post.data) -> <%= tag.attributes(data: post.data) %>
#   \lorem -> Lorem ipsum dolor sit amet…
#
# There's also a `t` sigil, but that's a little more involved since there's some extra things to condense:
#
#   \t.message -> <%= t ".message" %>
#   \t Some bare words -> <%= t "Some bare words" %> # Assumes we're using a gettext I18n backend, coming later!
module BRB; end
module BRB::Sigils
  @values = {}

  def self.gsub!(source)
    source.gsub!(/\\(#{@values.keys.join("|")})=?(?:(\.\w+)+|\((.*?)\))/) { p $1, $2, $3; @values[$1].sub('\1', $2 || $3) }
  end

  def self.register(key, replacer)
    @values[key.to_s] = replacer
  end

  register :t, '\= t "\1"'
  register :class, %(class="\\= class_names(\\1)")
  register :attributes, '\= tag.attributes(\1)'
  register :p, '\= tag.attributes(\1)'
  register :data, '\= tag.attributes(data: \1)'
  register :lorem, <<~end_of_lorem
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
  end_of_lorem
end

class BRB::Erubi < ::ActionView::Template::Handlers::ERB::Erubi
  # DEFAULT_REGEXP = /<%(={1,2}|-|\#|%)?(.*?)([-=])?%>([ \t]*\r?\n)?/m
  # DEFAULT_REGEXP = /<%(={1,2}|-|\#|%)?(.*?)([-=])?%>([ \t]*\r?\n)?/m

  # BRB aims to be a simpler syntax, but still a superset of ERB, that's aware of the context we're in: HTML.
  #
  # We're replacing <% %>, <%= %>, and <%# %> with \, \= and \# — these are self-terminating expressions.
  #
  # We recognize these contexts and convert them to their terminated ERB equivalent:
  #
  # 1. A plain Ruby line: \puts "yo" -> <%puts "yo" %>
  # 2. Within a tag: <h1>\= post.title</h1> -> <h1><%= post.title %></h1>
  # 3. Within attributes at the end: <h1 \= post.options></h1> -> <h1 aria-labelledby="title"></h1>
  # 4. Within attributes:
  #    <h1 \= post.options \= class_names(active: post.active?) data-controller="title"></h1> ->
  #    <h1 aria-labelledby="title" class="active"data-controller="title"></h1>
  def initialize(input, ...)
    puts input
    # scanner = StringScanner.new(input)
    # while string = scanner.scan_until(/\\/)
    #   binding.irb
    #   if scanner.bol? && scanner.check(/\n/)
    #     puts "YO"
    #   end
    #   p string
    # end

    if BRB::Sigils.gsub!(input)
      puts ["sigils", input] unless input.include?("clobbering")
    end

    if input.gsub!(/^\\\r?\n(.*?)^\\\r?\n/m, "<%\n\\1%>\n")
      # puts ["group", input] unless input.include?("clobbering")
    end

    # if input.gsub!(/(?<!\/)\\(.*?)(\"?\>|\<\/|[ \t]*\r?\n)/, '<%\1 %>\2')
    if input.gsub!(/(?<!\/)\\(.*?)(?=\n|"? \\|"?>|<\/|(?<!\/)\\|[a-z-]+=)/, '<%\1 %>')
      puts ["line", input] unless input.include?("clobbering")
    end
    super
  end
end

ActionView::Template::Handlers::ERB.erb_implementation = BRB::Erubi
