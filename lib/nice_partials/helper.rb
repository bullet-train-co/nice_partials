require_relative "partial"

module NicePartials::Helper
  def nice_partial
    NicePartials::Partial.new(self)
  end
  alias_method :np, :nice_partial
end
