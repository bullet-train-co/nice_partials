# Monkey patch required to make `t` work as expected. Is this evil?
# TODO Do we need to monkey patch other types of renderers as well?
class ActionView::PartialRenderer
  alias_method :original_render, :render

  # See `content_for` in `lib/nice_partials/partial.rb` for something similar.
  def render(partial, context, block)
    if block
      partial_prefix = NicePartials.locale_prefix_from_view_context_and_block(context, block)
      context.nice_partials_push_t_prefix partial_prefix
    else
      # Render partial calls with no block should disable any prefix magic.
      context.nice_partials_push_t_prefix ''
    end

    original_render(partial, context, block)
  ensure
    context.nice_partials_pop_t_prefix
  end
end
