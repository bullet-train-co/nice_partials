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

require "active_support/deprecation"
NicePartials::DEPRECATOR = ActiveSupport::Deprecation.new("1.0", "nice_partials")

module NicePartials::RenderingWithAutoContext
  ActionView::Base.prepend self

  def partial
    @partial ||= nice_partial
  end

  def p(*args)
    if args.empty?
      NicePartials::DEPRECATOR.deprecation_warning :p, :partial # In-branch printing so we don't warn on legit `Kernel.p` calls.
      partial
    else
      super # …we're really Kernel.p
    end
  end

  def render(options = {}, locals = {}, &block)
    _partial, @partial = @partial, nil
    super
  ensure
    @partial = _partial
  end

  def _layout_for(*arguments, &block)
    if block && !arguments.first.is_a?(Symbol)
      partial.capture(*arguments, &block)
    else
      super
    end
  end
end

module NicePartials::PartialRendering
  ActionView::PartialRenderer.prepend self

  def render_partial_template(view, locals, template, layout, block)
    view.partial.capture(&block) if block && !template.has_capturing_yield?
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
      @has_capturing_yield = source.match?(/\byield[\(? ]+(%>|[^:])/)
  end
end
