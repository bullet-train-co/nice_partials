require_relative "partial"

module NicePartials::Helper
  def nice_partial_with(local_assigns)
    NicePartials::Partial.new(self, local_assigns)
  end

  def nice_partial
    NicePartials::Partial.new(self)
  end
  alias_method :np, :nice_partial
end
