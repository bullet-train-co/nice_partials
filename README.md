# nice_partials [![[version]](https://badge.fury.io/rb/nice_partials.svg)](https://badge.fury.io/rb/nice_partials)

Nice Partials adds ad-hoc named content areas, or sections, to Action View partials with a lot of extra power.

Here we're using the `partial` method from Nice Partials, and outputting the `image`, `title`, and `body` sections:

`app/views/components/_card.html.erb`:
```html+erb
<div class="card">
  <%= partial.image %>
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

Then in `render`, you can populate them:

```html+erb
<%= render "components/card", title: "Some Title" do |partial| %>
  <% partial.title t(".title") %>

  <% partial.body do %>
    Lorem ipsum dolor sit amet, …
  <% end %>

  <% partial.image do %>
    <%= image_tag image_path("example.jpg"), alt: "An example image" %>
  <% end %>
<% end %>
```

So far these are pretty similar to Rails' global `content_for` & `content_for?`, except these sections are local to the specific partial, so there's no clashes or leaking.

### What can't you do with Rails' partials?

Having a `partial` object gives us a lot of power that's hard to replicate in standard Rails partials.

#### Appending content from the view into a section

Nice Partials supports calling any method on `ActionView::Base`, like the helpers shown here, and then have them auto-append to the section.

```html+erb
<%= render "components/card", title: "Some Title" do |partial| %>
  <% partial.title.t ".title" %>
  <% partial.body.render "form", tangible_thing: @tangible_thing %>
  <% partial.image.image_tag image_path("example.jpg"), alt: "An example image" %>
<% end %>
```

#### I18n: translating and setting multiple keys at a time

`partial.t` is a shorthand to translate and assign multiple keys at once:

```html+erb
<% partial.t :title, description: :header, byline: "custom.key" %>

# This is the same as writing:
<% partial.title t(".title") %>
<% partial.description t(".header") %>
<% partial.byline t("custom.key") %>
```

#### Capturing options and building HTML tags

You can pass keyword options to a writer method and they'll be auto-added to `partial.x.options`, like so:

```html+erb
<%= render "components/card" do |partial| %>
  <% partial.title "Title content", class: "text-m4", data: { controller: "title" } %>
<% end %>

# app/views/components/_card.html.erb:
# From the render above `title.options` now contain `{ class: "text-m4", data: { controller: "title" } }`.
# The options can be output via `<%=` and are run through `tag.attributes` to be converted to HTML attributes.

<h1 <%= partial.title.options %>><%= partial.title %></h1> # => <h1 class="text-m4" data-controller="title">Title content</h1>
```

`partial` also supports auto-generating an element by calling any of Rails' `tag` methods e.g.:

```html+erb
This shorthand gets us the same h1 element from the previous example:
<%= partial.title.h1 %> # => <h1 class="text-m4" data-controller="title">Title content</h1>

# Internally, this is similar to doing:
<%= tag.h1 partial.title.to_s, partial.title.options %>
```

#### Yielding tag builders into the partial's rendering block

The above example showed sending options from the rendering block into the partial and having it construct elements.

But the partial can also prepare tag builders that the rendering block can then extend and finalize:

```html+erb
<% render "components/card" do |partial|
  <% partial.title { |tag| tag.h1 "Title content" } %>
<% end %>

# app/views/components/_card.html.erb
<% partial.title.yield tag.with_options(class: "text-m4", data: { controller: "title" }) %> # => <h1 class="text-m4" data-controller="title">Title content</h1>
```

#### Smoother conditional rendering

In regular Rails partials it's common to see `content_for?` used to conditionally rendering something. With Nice Partials we can do this:

```html+erb
<% if partial.title? %>
  <% partial.title.h1 %>
<% end %>
```

But since sections respond to and leverage `present?`, we can shorten the above to:

```html+erb
<% partial.title.presence&.h1 %>
```

This way no empty h1 element is rendered.

#### Accessing the content returned via `partial.yield`

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

#### Defining and using well isolated helper methods

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


## Benefits of Nice Partials

Nice Partials:

  - are regular Rails view partials.
  - reduces the friction when extracting components.
  - only ends up in the specific partials you need its functionality in.
  - reduces context switching.
  - allows isolated helper logic alongside your partial view code.
  - doesn't require any upgrades to existing partials for interoperability.
  - are still testable!

Nice Partials are a lightweight and more Rails-native alternative to [ViewComponent](http://viewcomponent.org). Providing many of the same benefits as ViewComponent with less ceremony.

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
