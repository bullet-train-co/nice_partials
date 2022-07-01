# nice_partials [![[version]](https://badge.fury.io/rb/nice_partials.svg)](https://badge.fury.io/rb/nice_partials)  [![[travis]](https://travis-ci.org/andrewculver/nice_partials.svg)](https://travis-ci.org/andrewculver/nice_partials)

Nice Partials extends the concept of [`content_for` blocks and `yield`](https://guides.rubyonrails.org/layouts_and_rendering.html#using-the-content-for-method) for those times when a partial needs to provide one or more named "content areas" or "slots". This thin, optional layer of magic helps make traditional Rails view partials an even better fit for extracting components from your views, like so:

`app/views/components/_card.html.erb`:
```html+erb
<div class="card">
  <%= p.yield :image %>
  <div class="card-body">
    <h5 class="card-title"><%= title %></h5>
    <% if p.content_for? :body %>
      <p class="card-text">
        <%= p.yield :body %>
      </p>
    <% end %>
  </div>
</div>
```

These partials can still be utilized with a standard `render` call, but you can specify how to populate the content areas like so:

```html+erb
<%= render 'components/card', title: 'Some Title' do |p| %>
  <% p.content_for :body do %>
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    <strong>quis nostrud exercitation ullamco laboris</strong> nisi ut aliquip
    ex ea commodo consequat.
  <% end %>

  <% p.content_for :image do %>
    <%= image_tag image_path('example.jpg'), alt: 'An example image' %>
  <% end %>
<% end %>
```

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

 - is just regular Rails view partials like you're used to.
 - reduces the friction when extracting components.
 - only ends up in the specific partials you need its functionality in.
 - reduces context switching.
 - allows isolated helper logic alongside your partial view code.
 - doesn't require any upgrades to existing partials for interoperability.
 - are still testable!


## Can't I do the same thing without Nice Partials?

You can almost accomplish the same thing without Nice Partials, but in practice you end up having to flush the content buffers after using them, leading to something like this:

```html+erb
<div class="card">
  <%= yield :image %>
  <% content_for :image, flush: true do '' end %>
  <div class="card-body">
    <h5 class="card-title"><%= title %></h5>
    <% if content_for? :body %>
      <p class="card-text">
        <%= yield :body %>
        <% content_for :body, flush: true do '' end %>
      </p>
    <% end %>
  </div>
</div>
```

Earlier iterations of Nice Partials aimed to simply clean up this syntax with helper methods like `flush_content_for`, but because the named content buffers were in a global namespace, it was also possible to accidentally create situations where two partials with a `:body` content area would end up interfering with each other, depending on the order they're nested and rendered.

Nice Partials resolves the last-mile issues with standard view partials and content buffers by introducing a small, generic object that helps transparently namespace your named content buffers. This same object can also be used to define helper methods specific to your partial that are isolated from the global helper namespace.


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

### Invoking Nice Partials

Nice Partials is invoked automatically when you render your partial with a block that takes a single parameter like so:

```html+erb
<%= render 'components/card' do |p| %>
  <%= p.content_for :some_section %>
    Some content!
  <% end %>
<% end %>
```

It's always been natural to pass blocks to a partial in Rails, but not to pass blocks that take parameters, so when you do this, we know it's a partial that uses Nice Partials.

Now within the partial file itself, you can use `<%= p.yield :some_section %>` to render whatever content areas you want to be passed into your partial.

### Defining and using well isolated helper methods

To minimize the amount of pollution in the global helper namespace, you can use the shared context object to define helper methods specifically for your partials _within your partial_ like so:

```html+erb
<% p.helpers do

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
<td><%= p.reference_to(user) %></td>
```

## Development

### Testing

```sh
bundle exec rake test
```

## MIT License

Copyright (C) 2020 Andrew Culver <https://bullettrain.co> and Dom Christie <https://domchristie.co.uk>. Released under the MIT license.
