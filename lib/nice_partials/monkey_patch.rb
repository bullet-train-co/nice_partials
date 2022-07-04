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

require "active_support/deprecation"
NicePartials::DEPRECATOR = ActiveSupport::Deprecation.new("1.0", "nice_partials")

module NicePartials::RenderingWithAutoContext
  attr_reader :partial
  delegate :content_for?, :content_for, to: :partial

  def p(*args)
    if args.empty?
      NicePartials::DEPRECATOR.deprecation_warning :p, :partial # In-branch printing so we don't warn on legit `Kernel.p` calls.
      partial
    else
      super # …we're really Kernel.p
    end
  end

  def render(options = {}, locals = {}, &block)
    _partial, @partial = partial, nice_partial
    _layout_for(&block) # if !@current_template || @current_template.has_capturing_yield?
    super
  ensure
    @partial = _partial
  end

  # <%= yield %> # Stores the yield in output_buffer
  # <%= partial.yield %> # Access via yield without capturing again
  # <%= yield :message %> # Automatically read from the captured `partial` content
  def _layout_for(*arguments, &block)
    if arguments.first.is_a?(Symbol)
      partial.content_for(*arguments)
    elsif block
      partial.output_buffer ||= capture(*arguments, partial, &block)
    end
  end
end

ActionView::Template.prepend Module.new {
  def has_capturing_yield?
    # Matches plain yields that'll end up calling `capture`:
    #   <%= yield %>
    #   <%= yield something_else %>
    #
    # Doesn't match obfuscated `content_for` invocations:
    #   <%= yield :message %>
    source.match? /\byield[\(? ]+[^:]/
  end
}

ActionView::Base.prepend NicePartials::RenderingWithLocalePrefix
ActionView::Base.prepend NicePartials::RenderingWithAutoContext
