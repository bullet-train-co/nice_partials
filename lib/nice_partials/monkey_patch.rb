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
  attr_reader :partial

  def p(*args)
    args.empty? ? partial : super
  end

  def render(options = {}, locals = {}, &block)
    _partial, @partial = partial, nice_partial
    @partial.capture(block)
    super
  ensure
    @partial = _partial
  end
end

ActionView::Base.prepend NicePartials::RenderingWithLocalePrefix
ActionView::Base.prepend NicePartials::RenderingWithAutoContext
