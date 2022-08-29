class NicePartials::Partial::Section < NicePartials::Partial::Content
  def content_for(*arguments, &block)
    if write_content_for(arguments.first, &block)
      nil
    else
      capture_content_for(*arguments) if pending?
      @content
    end
  end

  def content?
    pending? || @content
  end

  private

  def write_content_for(content = nil, &block)
    if content && !pending?
      concat content
    else
      @pending_content = block if block
    end
  end

  def capture_content_for(*arguments)
    concat @view_context.capture(*arguments, &@pending_content)
    @pending_content = nil
  end

  def pending?
    @pending_content
  end
end
