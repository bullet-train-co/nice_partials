require_relative "partial"

module NicePartials::Helper
  def np
    NicePartials::Partial.new(self)
  end

  def nice_partials_push_t_prefix(prefix)
    @_nice_partials_t_prefixes ||= []
    @_nice_partials_t_prefixes << prefix
  end

  def nice_partials_pop_t_prefix
    @_nice_partials_t_prefixes ||= []
    @_nice_partials_t_prefixes.pop
  end

  def t(key, options = {})
    if @_nice_partials_t_prefixes&.any? && key.first == '.'
      key = "#{@_nice_partials_t_prefixes.last}#{key}"
    end

    super(key, **options)
  end
end
