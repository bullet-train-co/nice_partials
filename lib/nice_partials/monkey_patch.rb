# Monkey patch required to make `t` work as expected. Is this evil?
# TODO Do we need to monkey patch other types of renderers as well?
module NicePartials::RenderingWithLocalePrefix
  # See `content_for` in `lib/nice_partials/partial.rb` for something similar.
  def render(*, &block)
    with_nice_partials_t_prefix(lookup_context, block) { super }
  end

  def capture(*, &block)
    with_nice_partials_t_prefix(lookup_context, block) { super }
  end

  def t(key, options = {})
    if (prefix = @_nice_partials_t_prefixes&.last) && key.first == '.'
      key = "#{prefix}#{key}"
    end

    super(key, **options)
  end

  private

  def with_nice_partials_t_prefix(lookup_context, block)
    @_nice_partials_t_prefixes ||= []
    @_nice_partials_t_prefixes << (block ? NicePartials.locale_prefix_from(lookup_context, block) : '')
    yield
  ensure
    @_nice_partials_t_prefixes.pop
  end
end

ActionView::Base.prepend NicePartials::RenderingWithLocalePrefix
