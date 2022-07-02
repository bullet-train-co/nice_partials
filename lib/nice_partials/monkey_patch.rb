# Monkey patch required to make `t` work as expected. Is this evil?
# TODO Do we need to monkey patch other types of renderers as well?
module NicePartials::RenderingWithLocalePrefix
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
  def content
    @content ||= nice_partial
  end
  alias_method :_p, :content

  def p(*args)
    args.empty? ? _p : super
  end

  def render(*, &block)
    _auto_captured_output_buffer, _content, @content = @auto_captured_output_buffer, content, nil

    # Auto-capture a block passed to render…
    @auto_captured_output_buffer =
      case block&.arity
      when 0 then capture(&block) # …without arguments to capture `content`/`_p`.
      when 1 then capture(content, &block) # …with one argument we're expecting callers to expect a NicePartial::Partial.
      end

    # Expose any auto-captured buffer to any referenced `content` from within `capture`.
    @content&.output_buffer = @auto_captured_output_buffer

    super
  ensure
    @auto_captured_output_buffer, @content = _auto_captured_output_buffer, _content
  end

  def _layout_for(*args, &block)
    if block && !args.first.is_a?(Symbol)
      # Avoid calling capture again if we've already auto-captured.
      @auto_captured_output_buffer || capture(*args, &block)
    else
      super
    end
  end
end

ActionView::Base.prepend NicePartials::RenderingWithLocalePrefix
ActionView::Base.prepend NicePartials::RenderingWithAutoContext
