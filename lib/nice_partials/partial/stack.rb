class NicePartials::Partial::Stack
  def initialize
    @partials = []
    reset_locator
  end
  delegate :prepend, :shift, :first, to: :@partials

  def partial
    @partials.public_send @locator
  end

  def locate_previous
    @locator = :second
  end

  def reset_locator
    @locator = :first
  end
end
