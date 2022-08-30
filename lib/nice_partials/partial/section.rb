class NicePartials::Partial::Section < NicePartials::Partial::Content
  def yield(*arguments)
    chunks.each { concat @view_context.capture(*arguments, &_1) }
    self
  end

  # Allows for doing `partial.body.render "form", tangible_thing: @tangible_thing`
  def render(...)
    concat @view_context.render(...)
    self
  end

  def present?
    chunks.present? || super
  end

  private

  def capture(block)
    if block&.arity&.nonzero?
      chunks << block
    else
      super
    end
  end

  def chunks() = @chunks ||= []
end
