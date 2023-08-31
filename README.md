# nice_partials [![[version]](https://badge.fury.io/rb/nice_partials.svg)](https://badge.fury.io/rb/nice_partials)

Nice Partials adds ad-hoc named content areas, or sections, to Action View partials with a lot of extra power on top.

Everything happens through a new `partial` method, which at the base of it have method shorthands for partial specific `content_for` and `content_for?`s.

See, here we're outputting the `image`, `title`, and `body` sections:

`app/views/components/_card.html.erb`:
```html+erb
<div class="card">
  <%= partial.image %> # Same as `partial.content_for :image`
  <div class="card-body">
    <h5 class="card-title"><%= partial.title %></h5>
    <% if partial.body? %>
      <p class="card-text">
        <%= partial.body %>
      </p>
    <% end %>
  </div>
</div>
```

Then in `render` we populate them:

```html+erb
<%= render "components/card" do |partial| %>
  <% partial.title t(".title") %> # Same as `partial.content_for :title, t(".title")`

  <% partial.body do %>
    Lorem ipsum dolor sit amet, …
  <% end %>

  <% partial.image do %>
    <%= image_tag image_path("example.jpg"), alt: "An example image" %>
  <% end %>
<% end %>
```

So far these uses are pretty similar to Rails' global `content_for` & `content_for?`, except these sections are local to the specific partial, so there's no clashing or leaking.

### More-in depth compared to regular Rails partials

Consider this regular Rails partials rendering:

```html+erb
<%= render "components/card" do %>
  <% content_for :title, "Title content" %>
<% end %>

# app/views/components/_card.html.erb
<%= yield :title %>
<%= yield %>
```

There's a number of gotchas here:

- The `content_for` writes to `:title` across every partial, thus leaking.
- The rendering block isn't called until `<%= yield %>` is, so the `content_for` isn't called and `<%= yield :title %>` outputs nothing.

With Nice Partials the yield is automatic and we can write content for just that partial without leaking:

```html+erb
<%= render "components/card" do |partial| %>
  <% partial.title "Title content" %>
<% end %>

# app/views/components/_card.html.erb
<%= partial.title %>
```

This happens because Nice Partials checks the partial source code for any `yield` calls that calls Rails' `capture` helper — e.g. `yield` and `yield something` but not `yield :title`. If there's no capturing yields Nice Partials calls `capture` for you.

This means Nice Partials also respect existing yield calls in your partial, so you can upgrade existing partials bit by bit or not at all if you don't want to.

Nice Partials:

  - are still regular Rails view partials.
  - reduces the friction when extracting components.
  - only ends up in the specific partials you need the functionality.
  - reduces context switching.
  - allows isolated helper logic alongside your partial view code.
  - doesn't require any upgrades to existing partials for interoperability.
  - are still testable!

Nice Partials are a lightweight and more Rails-native alternative to [ViewComponent](http://viewcomponent.org). Providing many of the same benefits as ViewComponent with less ceremony.

## What extra powers does `partial` give me?

Having a `partial` object lets us add abstractions that are hard to replicate in standard Rails partials.

### Passing content from the render call

Nice Partials will use Action View's `local_assigns`, which stores any `locals` passed to `render`, as the basis for contents.

Given a partial like

```html+erb
<%# app/views/components/_card.html.erb %>
<%= partial.title %> written by <%= partial.byline %>
```

Can then be used like this:

```html+erb
<%= render "components/card", title: "Hello there", byline: "Some guy" do |partial| %>
  <% partial.byline ", who writes stuff" %>
<% end %>
```

This will then output "Hello there written by Some guy, who writes stuff"

You can also use `slice` to pass on content from an outer partial:

```html+erb
<%= render "components/card", partial.slice(:title, :byline) %>
```

### Declaring content as optional or required

In traditional Rails partials, you'll see lots of checks for whether or not we have content to then output an element.

With Nice Partials, it would look like this:

```html+erb
<% if partial.title? %>
  <h1 class="text-xl"><%= partial.title %></h1>
<% end %>
```

However, we can remove the conditional using `optional`:

```html+erb
<%= partial.title.optional.then do |title| %>
  <h1 class="text-xl"><%= title %></h1>
<% end %>
```

This will avoid outputting an empty tag, which could mess with your markup, in case there's no content provided for `title`.

Note: with Nice Partials tag helpers support, this example could also be shortened to `<%= partial.title.optional.h1 class: "text-xl" %>`.

#### Required

Alternatively, if `title` is a section that we require to be provided, we can do:

```html+erb
<h1 class="text-xl"><%= partial.title.required %></h1>
```

Here, `required` will raise in case there's been no `title` content provided by that point.

### Appending content from the view into a section

Nice Partials supports calling any method on `ActionView::Base`, like the helpers shown here, and then have them auto-append to the section.

```html+erb
<%= render "components/card" do |partial| %>
  <% partial.title.t ".title" %>
  <% partial.body.render "form", tangible_thing: @tangible_thing %>
  <% partial.image.image_tag image_path("example.jpg"), alt: "An example image" %>
<% end %>
```

### I18n: translating and setting multiple keys at a time

`partial.t` is a shorthand to translate and assign multiple keys at once:

```html+erb
<% partial.t :title, description: :header, byline: "custom.key" %>

# The above is the same as writing:
<% partial.title t(".title") %>
<% partial.description t(".header") %>
<% partial.byline t("custom.key") %>
```

### Capturing options in the rendering block and building HTML tags in the partial

You can pass keyword options to a writer method and they'll be auto-added to `partial.x.options`, like so:

```html+erb
<%= render "components/card" do |partial| %>
  <% partial.title "Title content", class: "text-m4", data: { controller: "title" } %>
<% end %>

# app/views/components/_card.html.erb:
# From the render above `title.options` now contain `{ class: "text-m4", data: { controller: "title" } }`.
# The options can be output via `<%=` and are automatically run through `tag.attributes` to be converted to HTML attributes.

<h1 <%= partial.title.options %>><%= partial.title %></h1> # => <h1 class="text-m4" data-controller="title">Title content</h1>
```

`partial` also supports auto-generating an element by calling any of Rails' `tag` methods e.g.:

```html+erb
# This shorthand gets us the same h1 element from the previous example:
<%= partial.title.h1 %> # => <h1 class="text-m4" data-controller="title">Title content</h1>

# Internally, this is similar to doing:
<%= tag.h1 partial.title.to_s, partial.title.options %>
```

### Yielding tag builders into the rendering block

The above example showed sending options from the rendering block into the partial and having it construct elements.

But the partial can also prepare tag builders that the rendering block can then extend and finalize:

```html+erb
<% render "components/card" do |partial|
  <% partial.title { |tag| tag.h1 "Title content" } %>
<% end %>

# app/views/components/_card.html.erb
<% partial.title.yield tag.with_options(class: "text-m4", data: { controller: "title" }) %> # => <h1 class="text-m4" data-controller="title">Title content</h1>
```

### Accessing the content returned via `partial.yield`

To access the inner content lines in the block here, partials have to manually insert a `<%= yield %>` call.

```html+erb
<%= render "components/card" do %>
  Some content!
  Yet more content!
<% end %>
```

With Nice Partials, `partial.yield` returns the same content:

```html+erb
# app/views/components/_card.html.erb
<%= partial.yield %> # => "Some content!\n\nYet more content!"
```

### Referring to the outer partial while rendering another

During a rendering block `partial` refers to the outer partial, so you can compose them.

```html+erb
<% partial.title "Title content" %>

<%= render "components/card" do |cp| %>
  <% cp.title partial.title %>
<% end %>
```

### Passing content from one partial to the next

If you need to pass content into another partial, `content_from` lets you pass the keys to extract and then a hash to rename keys.

```html+erb
<%= render "components/card" do |cp| %>
  <% cp.content_from partial, :title, byline: :header %>
<% end %>
```

Here, we copied the `partial.title` to `cp.title` and `partial.byline` became `cp.header`.

### Defining and using well isolated helper methods

If you want to have helper methods that are available only within your partials, you can call `partial.helpers` directly:

```html+erb
# app/views/components/_card.html.erb
<% partial.helpers do
  # references should be a link if the user can drill down, otherwise just a text label.
  def reference_to(user)
    # look! this method has access to the scope of the entire view context and all the other helpers that come with it!
    if can? :show, user
      link_to user.name, user
    else
      object.name
    end
  end
end %>

# Later in the partial we can use the method:
<td><%= partial.reference_to(user) %></td>
```

## Sponsored By

<a href="https://bullettrain.co" target="_blank">
  <img src="https://github.com/CanCanCommunity/cancancan/raw/develop/logo/bullet_train.png" alt="Bullet Train" width="400"/>
</a>
<br/>
<br/>

> Would you like to support Nice Partials development and have your logo featured here? [Reach out!](http://twitter.com/andrewculver)


## Setup

Add to your `Gemfile`:

```ruby
gem "nice_partials"
```

### Testing

```sh
bundle exec rake test
```

## MIT License

Copyright (C) 2022 Andrew Culver <https://bullettrain.co> and Dom Christie <https://domchristie.co.uk>. Released under the MIT license.
