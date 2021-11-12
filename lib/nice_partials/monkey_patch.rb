# Monkey patch required to make `t` work as expected. Is this evil?
# TODO Do we need to monkey patch other types of renderers as well?
class ActionView::PartialRenderer
  alias_method :original_render, :render

  # See `content_for` in `lib/nice_partials/partial.rb` for something similar.
  def render(partial, context, block)
    if block
      partial_prefix = nice_partials_locale_prefix_from_view_context_and_block(context, block)
      context.nice_partials_push_t_prefix partial_prefix
    else
      # Render partial calls with no block should disable any prefix magic.
      context.nice_partials_push_t_prefix ''
    end

    result = original_render(partial, context, block)

    # Whether there was a block or not, pop off whatever we put on the stack.
    context.nice_partials_pop_t_prefix

    return result
  end

  # This and ActionView::Template#render below are for compatibility
  # with Ruby 3, as opposed to altering the original functionality.
  def render_partial_template(view, locals, template, layout, block)
    ActiveSupport::Notifications.instrument(
      "render_partial.action_view",
      identifier: template.identifier,
      layout: layout && layout.virtual_path
    ) do |payload|
      content = template.render(view, locals, ActionView::OutputBuffer.new, {add_to_stack: !block}) do |*name|
        view._layout_for(*name, &block)
      end

      content = layout.render(view, locals) { content } if layout
      payload[:cache_hit] = view.view_renderer.cache_hits[template.virtual_path]
      build_rendered_template(content, template)
    end
  end
end

class ActionView::Template
  def render(view, locals, buffer = ActionView::OutputBuffer.new, flag = {add_to_stack: true}, &block)
    instrument_render_template do
      compile!(view)
      view._run(method_name, self, locals, buffer, **flag, &block)
    end
  rescue => e
    handle_render_error(view, e)
  end
end
