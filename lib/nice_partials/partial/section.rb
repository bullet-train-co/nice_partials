class NicePartials::Partial::Section
  def initialize(view_context)
    @view_context = view_context
    @content = @pending_content = nil
  end

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

  def concat(string)
    @content ||= ActiveSupport::SafeBuffer.new
    @content << string.to_s if string.present?
  end

  def pending?
    @pending_content
  end
end
