class NicePartials::Partial::Content
  def initialize(view_context)
    @view_context, @content = view_context, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, :present?, to: :@content

  def write(content = nil, &block)
    append content or capture block
  end

  private

  def capture(block)
    append @view_context.capture(&block) if block
  end

  def append(content)
    concat content
  end

  def concat(string)
    @content << string.to_s if string.present?
  end
end
