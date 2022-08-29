class NicePartials::Partial::Content
  def initialize(view_context)
    @view_context, @content = view_context, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, to: :@content

  def content?
    @content.present?
  end

  def content_for(content = nil, &block)
    self unless concat(content || capture(block))
  end

  private

  def capture(block)
    @view_context.capture(&block) if block
  end

  def concat(string)
    @content << string.presence&.to_s
    string
  end
end
