## CHANGELOG

* Let partials respond to named content sections

  ```erb
  <% partial.content_for :title, "Title content" %> # Before
  <% partial.title "Title content" %> # After

  # Which can then be output
  <% partial.title %> # => "Title content"
  <% partial.title? %> # => true
  ```

  Note, `title?` uses `present?` under the hood so rendering could also be made conditional with:

  ```erb
  <% partial.title if partial.title? %> # Instead of this…
  <% partial.title.presence %> # …you can do this
  ```

  #### Passing procs or components

  Procs and objects that implement render_in, like ViewComponents, can also be appended as content:

  ```erb
  <% partial.title { "some content" } %>
  <% partial.title TitleComponent.new(Current.user) %>
  ```

  #### Capturing `options`

  Options can also be captured and output:

  ```erb
  <% partial.title class: "text-m4" %> # partial.title.options # => { class: "text-m4" }

  # When output `to_s` is called and options automatically pipe through `tag.attributes`:
  <h1 <% partial.title.options %>> # => <h1 class="post-title">
  ```

  #### Proxying to the view context and appending content

  A content section appends to its content when calling any view context method on it, e.g.:

  ```erb
  <% partial.title.render "title", user: %>
  <% partial.title.link_to @document.name, @document %>
  <% partial.title.t ".title" %>
  ```

  #### Building elements with `tag` proxy

  These `tag` calls let you generate elements based on the stored content and options:

  ```erb
  <% partial.title "content", class: "post-title" %> # Adding some content and options…
  <% partial.title.h2 %> # => <h2 class="post-title">content</h2>
  <% partial.title.h2 "more" %> # => <h2 class="post-title">contentmore</h2>
  ```

* Add `NicePartials#t` to aid I18n.

  When using NicePartials with I18n you end up with lots of calls that look like:

  ```erb
  <% partial.title       t(".title") %>
  <% partial.description t(".header") %>
  <% partial.byline      t("custom.key") %>
  ```

  With NicePartials' `t` method, you can write the above as:

  ```erb
  <% partial.t :title, description: :header, byline: "custom.key" %>
  ```

  Clarifying what keys get converted to what content sections on the partial rather than the boilerplate heavy and repetitive `partial.… t(".…")`.

* Add `Partial#content_from`

  `content_from` lets a partial extract contents from another partial.
  Additionally, contents can be renamed by passing a hash:

  ```erb
  <% partial.title "Hello there" %>
  <% partial.byline "Somebody" %>

  <%= render "shared/title" do |cp| %>
    # Here the inner partial `cp` accesses the outer partial through `partial`
    # extracting the `title` and `byline` contents.
    # `byline` is renamed to `name` in `cp`.
    <% cp.content_from partial, :title, byline: :name %>
  <% end %>
  ```

### 0.1.9

* Remove need to insert `<% yield p = np %>` in partials.

  Nice Partials now automatically captures blocks passed to `render`.
  Instead of `p`, a `partial` method has been added to access the
  current `NicePartials::Partial` object.

  Here's a script to help update your view code:

  ```ruby
  files_to_inspect = []

  Dir["app/views/**/*.html.erb"].each do |path|
    if contents = File.read(path).match(/(<%=? yield\(?.*? = np\)? %>\n+)/m)&.post_match
      files_to_inspect << path if contents.match?(/render.*?do \|/)

      contents.gsub! /\bp\.(?=yield|helpers|content_for|content_for\?)/, "partial."
      File.write path, contents
    end
  end

  if files_to_inspect.any?
    puts "These files had render calls with a block parameter and likely require some manual edits:"
    puts files_to_inspect
  else
    puts "No files with render calls with a block parameter found, you're likely all set"
  end
  ```

* Support manual `yield`s in partials.

  Due to the automatic yield support above, support has also been added for manual `yield some_object` calls.

  Nice Partials automatically appends the `partial` to the yielded arguments, so you can
  change `render … do |some_object|` to `render … do |some_object, partial|`.

* Deprecate `p` as the partial object access. Use `partial` instead.

* Expose `partial.yield` to access the captured output buffer.

  Lets you access what a `<%= yield %>` call returned, like this:

  ```erb
  <%= render "card" do %>
    This is the content of the internal output buffer
  <% end %>
  ```

  ```erb
  # app/views/cards/_card.html.erb
  # This can be replaced with `partial.yield`.
  <%= yield %> # Will output "This is the content of the internal output buffer"
  ```

### 0.1.7

* Rely on `ActiveSupport.on_load :action_view`
* Add support for Ruby 3.0

### 0.1.0

* Initial release
