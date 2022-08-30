class NicePartials::Partial::Content
  def initialize(view_context)
    @view_context, @content = view_context, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, :present?, to: :@content

  def write(content = nil, &block)
    concat content or capture block
  end

  private

  def capture(block)
    concat @view_context.capture(&block) if block
  end

  def concat(string)
    @content << string.to_s if string.present?
  end
end
