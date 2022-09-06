# Monkey patch required to make `t` work as expected. Is this evil?
# TODO Do we need to monkey patch other types of renderers as well?
module NicePartials::RenderingWithLocalePrefix
  ActionView::Base.prepend self

  def capture(*, &block)
    with_nice_partials_t_prefix(lookup_context, block) { super }
  end

  def t(key, options = {})
    if (prefix = @_nice_partials_t_prefix) && key.first == '.'
      key = "#{prefix}#{key}"
    end

    super(key, **options)
  end

  private

  def with_nice_partials_t_prefix(lookup_context, block)
    _nice_partials_t_prefix = @_nice_partials_t_prefix
    @_nice_partials_t_prefix = block ? NicePartials.locale_prefix_from(lookup_context, block) : nil
    yield
  ensure
    @_nice_partials_t_prefix = _nice_partials_t_prefix
  end
end

module NicePartials::RenderingWithAutoContext
  ActionView::Base.prepend self

  def __partials
    @__partials ||= NicePartials::Partial::Stack.new
  end
  delegate :partial, to: :__partials

  # Overrides `ActionView::Helpers::RenderingHelper#render` to push a new `nice_partial`
  # on the stack, so rendering has a fresh `partial` to store content in.
  def render(*)
    __partials.prepend nice_partial
    super
  ensure
    __partials.shift
  end

  # Since Action View passes any `yield`s in partials through `_layout_for`, we
  # override `_layout_for` to detects if it's a capturing yield and append the
  # current partial to the arguments.
  #
  # So `render … do |some_object|` can become `render … do |some_object, partial|`
  # without needing to find and update the inner `yield some_object` call.
  def _layout_for(*arguments, &block)
    if block && !arguments.first.is_a?(Symbol)
      capture_with_outer_partial_access(*arguments, &block)
    else
      super
    end
  end

  # Reverts `partial` to return the outer partial before the `render` call started.
  #
  # So we don't clobber the `partial` shown here:
  #
  #   <%= render "card" do |inner_partial| %>
  #     <% inner_partial.content_for :title, partial.content_for(:title) %>
  #   <% end %>
  #
  # Note: this happens because the `@partial` instance variable is shared between all
  # `render` calls since rendering happens in one `ActionView::Base` instance.
  def capture_with_outer_partial_access(*arguments, &block)
    __partials.locate_previous
    __partials.first.capture(*arguments, &block)
  ensure
    __partials.reset_locator
  end
end

module NicePartials::PartialRendering
  ActionView::PartialRenderer.prepend self

  # Automatically captures the `block` in case the partial has no manual capturing `yield` call.
  #
  # This manual equivalent would be inserting this:
  #
  #   <% yield partial %>
  def render_partial_template(view, locals, template, layout, block)
    view.capture_with_outer_partial_access(&block) if block && !template.has_capturing_yield?
    super
  end
end

module NicePartials::CapturingYieldDetection
  ActionView::Template.include self

  # Matches yields that'll end up calling `capture`:
  #   <%= yield %>
  #   <%= yield something_else %>
  #
  # Doesn't match obfuscated `content_for` invocations, nor custom yields:
  #   <%= yield :message %>
  #   <%= something.yield %>
  #
  # Note: `<%= yield %>` becomes `yield :layout` with no `render` `block`, though this method assumes a block is passed.
  def has_capturing_yield?
    defined?(@has_capturing_yield) ? @has_capturing_yield :
      @has_capturing_yield = source.match?(/[^\.\b]yield[\(? ]+(%>|[^:])/)
  end
end
