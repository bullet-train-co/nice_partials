class NicePartials::Partial::Section < NicePartials::Partial::Content
  def yield(*arguments)
    chunks.each { append @view_context.capture(*arguments, &_1) }
    self
  end

  def present?
    chunks.present? || super
  end

  undef_method :p # Remove Kernel.p here to pipe through method_missing and hit tag proxy.

  # Allows for doing `partial.body.render "form", tangible_thing: @tangible_thing`
  # and `partial.body.link_to @document.name, @document`
  def method_missing(meth, *arguments, **keywords, &block)
    if meth != :p && @view_context.respond_to?(meth)
      concat @view_context.public_send(meth, *arguments, **keywords, &block)
      nil
    else
      @view_context.tag.public_send(meth, @content + arguments.first.to_s, **options.merge(keywords), &block)
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
