# Monkey patch required to make `t` work as expected. Is this evil?
# TODO Do we need to monkey patch other types of renderers as well?
module NicePartials::RenderingWithLocalePrefix
  # See `content_for` in `lib/nice_partials/partial.rb` for something similar.
  def render(*, &block)
    if block
      partial_prefix = NicePartials.locale_prefix_from(lookup_context, block)
      nice_partials_push_t_prefix partial_prefix
    else
      # Render partial calls with no block should disable any prefix magic.
      nice_partials_push_t_prefix ''
    end

    super
  ensure
    nice_partials_pop_t_prefix
  end
end

ActionView::Base.prepend NicePartials::RenderingWithLocalePrefix
