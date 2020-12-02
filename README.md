# nice_partials [![[version]](https://badge.fury.io/rb/nice_partials.svg)](https://badge.fury.io/rb/nice_partials)  [![[travis]](https://travis-ci.org/andrewculver/nice_partials.svg)](https://travis-ci.org/andrewculver/nice_partials)

Nice Partials provides a light layer of magic on top of traditional Rails view partials to try and make them an even better fit for extracting and reusing components in your views. Nice Partials is specifically designed to be a lightweight and more Rails-native alternative to [ViewComponent](http://viewcomponent.org) that hopefully provides many of the same benefits while requiring less ceremony. This specific approach originated with [Bullet Train](https://bullettrain.co)'s "Field Partials" and was later reimagined and completely reimplemented by Dom Christie.


## Benefits

 - They're just partials like you're used to, with a few extra features.
 - Less context switching. Your components are all just rendering in the standard view context.
 - You don't have to upgrade your existing partials. You can still nest them in a Nice Partials content area.
 - Less ceremony. You _can_ spin up a custom class to back your partial if you want to, but you don't have to by default, and we don't suggest it.
 - Instead, skip the component class entirely! You can define appropriately scoped helpers right inline with your partial.
 - It's still testable. There's no reason why these can't be as testable as ViewComponents.


## Setup

Add to your `Gemfile`:

```ruby
gem "nice_partials"
```


## Usage

### Defining a Nice Partial

We'll define an example partial in `app/views/partials/_card.html.erb`. We start by invoking Nice Partials like so:

```
<% yield p = np %>
```

We can explain what each thing is doing there later, but for now just trust us that it's the minimum viable invocation that we're aware of at the moment.

After that, you can define your partial content and define your content areas:

```
<div class="card">
  <%= p.yield :image %>
  <div class="card-body">
    <h5 class="card-title"><%= title %></h5>
    <p class="card-text">
      <%= p.yield :body %>
    </p>
  </div>
</div>
```

That's it!

### Utilizing a Nice Partial

To use a Nice Partial, just render it like you would any other partial, but also pass a block that defines the content for the content areas like so:

```
<%= render 'partials/card', title: 'Some Title' do |p| %>
  <% p.content_for :body do %>
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
    Ut enim ad minim veniam, <strong>quis nostrud exercitation ullamco laboris</strong> nisi ut aliquip ex ea commodo consequat.
  <% end %>

  <% p.content_for :image do %>
    <%= image_tag image_path('example.jpg'), alt: 'An example image' %>
  <% end %>
<% end %>
```

### Defining and Using Well Isolated Helper Methods

To minimize the amount of pollution in the global helper namespace, you can define helper methods specifically for your partials _within your partial_ like so:

```
<% p.helpers do

  # references should be a link if the user can drill down, otherwise just a text label.
  # (this method has access to the scope of the entire view context and all the other helpers that come with it.)
  def reference_to(user)
    if can? :show, user
      link_to user.name, user
    else
      object.name
    end
  end

end %>
```

Then later in the partial you can use the helper method like so:

```
<td><%= p.reference_to(user) %></td>
```

## MIT License

Copyright (C) 2020 Andrew Culver <https://bullettrain.co> and Dom Christie <https://domchristie.co.uk>. Released under the MIT license.
