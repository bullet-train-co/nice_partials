require_relative "partial"

module NicePartials::Helper
  def np
    NicePartials::Partial.new(self)
  end
end
