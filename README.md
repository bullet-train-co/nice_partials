# nice_partials [![[version]](https://badge.fury.io/rb/nice_partials.svg)](https://badge.fury.io/rb/nice_partials)

Nice Partials adds ad-hoc named content areas to Action View partials with a lot of extra power.

Here we're using the `partial` method from Nice Partials, and printing out both the `image`, `title`, and `body` areas:

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

Then in `render`, you can populate the content areas:

```html+erb
<%= render 'components/card', title: "Some Title" do |partial| %>
  <% partial.title t(".title") %>

  <% partial.body do %>
    Lorem ipsum dolor sit amet, …
  <% end %>

  <% partial.image do %>
    <%= image_tag image_path("example.jpg"), alt: "An example image" %>
  <% end %>
<% end %>
```

So far this is pretty analogous to Rails' built-in `content_for` & `content_for?`, and `partial` does support both too. However, while Rails' `content_for` & `content_for?` are global, `partial.content_for` & `partial.content_for?` are local to the specific partial, so you don't have to worry about clashes or leaking.

Having a `partial` to call gives us a lot of power, here's another way we can write what you just saw above:

```html+erb
<%= render 'components/card', title: "Some Title" do |partial| %>
  <% partial.title.t ".title" %>
  <% partial.body.render "form", tangible_thing: @tangible_thing %>
  <% partial.image.image_tag image_path("example.jpg"), alt: "An example image" %>
<% end %>
```

Nice Partials supports calling any method on `ActionView::Base`, like the helpers shown above, and then have them auto-append to the content area.

Nice Partials is a lightweight and hopefully more Rails-native alternative to [ViewComponent](http://viewcomponent.org). It aims to provide many of the same benefits as ViewComponent while requiring less ceremony. This specific approach originated with [Bullet Train](https://bullettrain.co)'s "Field Partials" and was later reimagined and completely reimplemented by Dom Christie.


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

## Setup

Add to your `Gemfile`:

```ruby
gem "nice_partials"
```

## Usage

### When to use Nice Partials

You only need to use Nice Partials when:

 - you want to define one or more named content areas in your partial. If you don't have multiple named content areas in your partial, you could just pass your content into the partial using the standard block and `yield` approach.

 - you want to specifically isolate your helper methods for a specific partial.

### Using Nice Partials

Nice Partials is invoked automatically when you render your partial with a block like so:

```html+erb
<%= render 'components/card' do |partial| %>
  <%= partial.content_for :some_section do %>
    Some content!
  <% end %>
<% end %>
```

Now within the partial file itself, you can use `<%= partial.yield :some_section %>` to render whatever content areas you want to be passed into your partial.

### Accessing the content returned from `yield`

In a regular Rails partial:

```html+erb
<%= render 'components/card' do %>
  Some content!
  Yet more content!
<% end %>
```

You can access the inner content lines through what's returned from `yield`:

```html+erb
<%# app/views/components/_card.html.erb %>
<%= yield %> # => "Some content!\n\nYet more content!"
```

With Nice Partials, you can call `partial.yield` without arguments and return the same `"Some content!\n\nYet more content!"`.

### Defining and using well isolated helper methods

To minimize the amount of pollution in the global helper namespace, you can use the shared context object to define helper methods specifically for your partials _within your partial_ like so:

```html+erb
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
```

Then later in the partial you can use the helper method like so:

```html+erb
<td><%= partial.reference_to(user) %></td>
```

## Development

### Testing

```sh
bundle exec rake test
```

## MIT License

Copyright (C) 2020 Andrew Culver <https://bullettrain.co> and Dom Christie <https://domchristie.co.uk>. Released under the MIT license.
