## CHANGELOG

* Feature: partial's expose `local_assigns` + `locals` alias

  ```html+erb
  <%# app/views/articles/show.html.erb %>
  <%= render "section", id: "an_article" %>

  <%# app/views/application/_section.html.erb %>
  <%# We can access the passed `id:` like this: %>
  <% partial.local_assigns[:id] %>
  <% partial.locals[:id] %>
  ```

  Note: this is equal to the default partial local variable of `local_assigns`, but it becomes more useful with the next feature below.

* Feature: partial helpers can access `partial`

  ```html+erb
  <%# app/views/articles/show.html.erb %>
  <% render "section", id: "an_article" do |section| %>
    <%= tag.h1 "An Article", id: section.labelledby %>
  <% end %>

  <%# app/views/application/_section.html.erb %>
  <%
    partial.helpers do
      def aria
        partial.locals.fetch(:aria, {}).with_defaults(labelledby:)
      end

      def labelledby
        id = partial.locals[:id] and "#{id}_label"
      end
    end
  %>

  <%= tag.section partial.yield, id:, aria: partial.aria %>
  ```

### 0.9.4

* Feature: declare contents via `required` and `optional`

  ```html+erb
  <% if partial.title? %>
    <h1 class="text-xl">
      <%= partial.title %>
    </h1>
  <% end %>

  <div><%= partial.body %></div>
  ```

  Can now become:

  ```html+erb
  <%= partial.title.optional.h1 class: "text-xl" %><%# Will not output any HTML element if no content has been provided. %>

  <div><%= partial.body.required %></div> <%# Raises when this line is hit if no content has been provided %>
  ```

  See the README for more.

### 0.9.3

* Fixed: section predicates not respecting `local_assigns` content

  Previously, when doing something like this:

  ```erb
  <%= render "card", title: "Hello there" %>
  ```

  If the inner card partial had this,

  ```erb
  <% if partial.title? %>
    <%= partial.title %>
  <% end %>
  ```

  The `title?` predicate would fail, because it didn't look up content from the passed `local_assigns`. Now it does.

### 0.9.2

* Changed: view methods don't clobber section names

  Previously, we'd eagerly delegate to the view context so if the view had a `label` method, `partial.label` would call the view's `label` instead of making a `label` section.

  This was to support `partial.helpers` but we've changed the implementation to support the above. `partial.helpers` still works the same too.

* Changed: `partial.helpers` no longer automatically calls `partial` methods

  Previously, if a user defined a partial helper like this:

  ```ruby
  partial.helpers do
    def some_helper
      some_section
    end
  end
  ```

  If `some_section` wasn't a view method, it would automatically call `partial.some_section`
  thereby adding a new content section to the partial.

  Now `partial.helpers` behaves exactly like view helpers — making it easier to copy code directly when migrating — so users would have to explicitly call `partial.some_section`.

### 0.9.1

* Fix Ruby 2.7 compatibility

### 0.9.0

* Fix rendering with special characters in a view path.

  Ref: https://github.com/bullet-train-co/nice_partials/pull/70

* Seed Nice Partials content from `local_assigns`

  Previously, the only way to assign content to a Nice Partial was through passing a block:

  ```erb
  # app/views/posts/show.html.erb
  <%= render "posts/post", byline: "Some guy" %>

  # app/views/posts/_post.html.erb
  <%= render "card" do |partial| %>
    <% partial.title "Hello there" %>
    <% partial.byline byline %> <%# `byline` comes from the outer `render` call above. %>
  <% end %>

  Now, Nice Partials will automatically use Rails' `local_assigns`, which contain any `locals:` passed to `render`, as the seed for content. So this works:

  ```erb
  <%= render "card", title: "Hello there", byline: byline %>
  ```

  And the `card` partial is now oblivious to whether its `title` or `byline` were passed as render `locals:` or through the usual assignments in a block.

  ```erb
  # app/views/_card.html.erb
  <%= partial.title %> written by <%= partial.byline %>
  ```

  Previously to get this behavior you'd need to write:

  ```erb
  # app/views/_card.html.erb
  <%= partial.title.presence || local_assigns[:title] %> written by <%= partial.byline.presence || local_assigns[:byline] %>
  ```

  Passing extra content via a block appends:

  ```erb
  <%= render "card", title: "Hello there" do |partial| %>
    <% partial.title ", and welcome!" %> # Calling `partial.title` outputs `"Hello there, and welcome!"`
  <% end %>
  ```

* Add `NicePartials::Partial#slice`

  Returns a Hash of the passed keys with their contents, useful for passing to other render calls:

  ```erb
  <%= render "card", partial.slice(:title, :byline) %>
  ```

* Fix `partial.helpers` accidentally adding methods to `ActionView::Base`

  When using `partial.helpers {}`, internally `class_eval` would be called on the Partial instance, and through `delegate_missing_to` passed on to the view context and thus we'd effectively have a global method, exactly as if we'd just used regular Rails view helpers.

* Let partials respond to named content sections

  ```erb
  <% partial.content_for :title, "Title content" %> # Before
  <% partial.title "Title content" %> # After

  # Which can then be output
  <% partial.title %> # => "Title content"
  <% partial.title? %> # => true
  ```

  Note, `title` responds to `present?` so rendering could also be made conditional with:

  ```erb
  <% partial.title if partial.title? %> # Instead of this…
  <% partial.title.presence %> # …you can do this
  ```

  #### Passing procs or components

  Procs and objects that implement `render_in`, like ViewComponents, can also be appended as content:

  ```erb
  <% partial.title { "some content" } %>
  <% partial.title TitleComponent.new(Current.user) %>
  ```

  #### Capturing `options`

  Options can also be captured and output:

  ```erb
  <% partial.title class: "text-m4" %> # partial.title.options # => { class: "text-m4" }

  # When output `to_s` is called and options automatically pipe through `tag.attributes`:
  <h1 <% partial.title.options %>> # => <h1 class="text-m4">
  ```

  #### Proxying to the view context and appending content

  A content section appends to its content when calling any view context method on it, e.g.:

  ```erb
  <% partial.title.t ".title" %>
  <% partial.title.link_to @document.name, @document %>
  <% partial.title.render "title", user: Current.user %>
  <% partial.title.render TitleComponent.new(Current.user) do |component| %>
    <% … %>
  <% end %>
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

  Clarifying what keys get converted to what content sections on the partial rather than the syntax heavy `partial.… t(".…")`.

  Like the Rails built-in `t` method, it's just a shorthand alias for `translate` so that's available too.

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
