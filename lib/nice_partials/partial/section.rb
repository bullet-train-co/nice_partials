class NicePartials::Partial::Section < NicePartials::Partial::Content
  def yield(*arguments)
    chunks.each { concat @view_context.capture(*arguments, &_1) }
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
