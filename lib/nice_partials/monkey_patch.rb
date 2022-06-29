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
end

ActionView::Base.prepend NicePartials::RenderingWithLocalePrefix
