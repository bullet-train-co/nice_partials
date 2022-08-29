class NicePartials::Partial::Section < NicePartials::Partial::Content
  def store(*new_chunks, &block)
    chunks.concat new_chunks
    chunks << block if block_given?
    nil
  end

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
