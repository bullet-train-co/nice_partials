# frozen_string_literal: true

# Monkey patch required to make `t` work as expected. Is this evil?
# TODO Do we need to monkey patch other types of renderers as well?
module NicePartials::RenderingWithLocalePrefix
  module BaseIntegration
    ::ActionView::Base.prepend self

    def t(key, options = {})
      if (template = @_nice_partials_translate_template) && key&.start_with?(".")
        key = "#{virtual_path_translate_key_prefix(template.virtual_path)}#{key}"
      end

      super(key, **options)
    end

    def with_nice_partials_t_prefix(block)
      old_nice_partials_translate_template = @_nice_partials_translate_template
      @_nice_partials_translate_template = block ? @current_template : nil
      yield
    ensure
      @_nice_partials_translate_template = old_nice_partials_translate_template
    end

    private

    def virtual_path_translate_key_prefix(virtual_path)
      @_scope_key_by_partial_cache ||= {} # Reuses Rails' existing `t` cache.
      @_scope_key_by_partial_cache[virtual_path] ||= virtual_path.gsub(%r{/_?}, ".")
    end
  end

  module PartialRendererIntegration
    ActionView::PartialRenderer.prepend self

    def render(partial, view, block)
      view.with_nice_partials_t_prefix(block) { super }
    end
  end
end

require "active_support/deprecation"
NicePartials::DEPRECATOR = ActiveSupport::Deprecation.new("1.0", "nice_partials")

module NicePartials::RenderingWithAutoContext
  ActionView::Base.prepend self

  def __partials
    @__partials ||= NicePartials::Partial::Stack.new
  end
  delegate :partial, to: :__partials

  def p(*args)
    if args.empty?
      NicePartials::DEPRECATOR.deprecation_warning :p, :partial # In-branch printing so we don't warn on legit `Kernel.p` calls.
      partial
    else
      super # …we're really Kernel.p
    end
  end

  # Overrides `ActionView::Helpers::RenderingHelper#render` to push a new `nice_partial`
  # on the stack, so rendering has a fresh `partial` to store content in.
  def render(options = {}, locals = {}, &block)
    partial_locals = options.is_a?(Hash) ? options[:locals] : locals
    __partials.prepend nice_partial_with(partial_locals)
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
