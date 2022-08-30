class NicePartials::Partial::Section < NicePartials::Partial::Content
  def yield(*arguments)
    chunks.each { append @view_context.capture(*arguments, &_1) }
    self
  end

  def present?
    chunks.present? || super
  end

  # Allows for doing `partial.body.render "form", tangible_thing: @tangible_thing`
  # and `partial.body.link_to @document.name, @document`
  def method_missing(meth, *arguments, **keywords, &block)
    if @view_context.respond_to?(meth)
      concat @view_context.public_send(meth, *arguments, **keywords, &block)
      nil
    else
      super
    end
  end
  def respond_to_missing?(...) = @view_context.respond_to?(...)

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
