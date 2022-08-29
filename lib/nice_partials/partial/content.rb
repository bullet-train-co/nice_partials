class NicePartials::Partial::Content
  def initialize(view_context)
    @view_context, @content = view_context, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, :present?, to: :@content

  def write(*arguments, &block)
    arguments.append(block).compact.filter_map { _1.respond_to?(:call) ? capture(_1) : concat(_1) }.any?
  end

  private

  def capture(block)
    concat @view_context.capture(&block) if block
  end

  def concat(string)
    @content << string.presence&.to_s
    string
  end
end
