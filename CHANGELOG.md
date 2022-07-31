## CHANGELOG

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
    puts "No files with renders calls with a block parameter found, you're likely all set"
  end
  ```

* Support manual `yield`s in partials.

  Due to the automatic yield support above, support has also been added for manual `yield some_object` calls.

  Nice Partials automatically appends the `partial` to the yielded arguments, so you can
  change `render … do |some_object|` to `render … do |some_object, partial|`.

* Deprecate `p` as the partial object access. Use `partial` instead.

* Expose `partial.yield` to access the captured output buffer.

  Let's you access what a `<%= yield %>` call returned, like this:

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
