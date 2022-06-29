require_relative "partial"

module NicePartials::Helper
  def np
    NicePartials::Partial.new(self)
  end

  def with_nice_partials_t_prefix(lookup_context, block)
    @_nice_partials_t_prefixes ||= []
    @_nice_partials_t_prefixes << (block ? NicePartials.locale_prefix_from(lookup_context, block) : '')
    yield
  ensure
    @_nice_partials_t_prefixes.pop
  end

  def t(key, options = {})
    if (prefix = @_nice_partials_t_prefixes&.last) && key.first == '.'
      key = "#{prefix}#{key}"
    end

    super(key, **options)
  end
end
