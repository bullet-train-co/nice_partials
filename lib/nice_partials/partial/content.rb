class NicePartials::Partial::Content
  attr_reader :options

  def initialize(view_context)
    @view_context, @options, @content = view_context, {}, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, :present?, to: :@content

  def write(content = nil, **options, &block)
    @options.merge! options unless options.empty?
    append content or capture block
  end

  private

  def append(content)
    case
    when content.respond_to?(:render_in) then concat  content.render_in(@view_context)
    when content.respond_to?(:call)      then capture content
    else
      concat content
    end
  end

  def capture(block)
    append @view_context.capture(&block) if block
  end

  def concat(string)
    @content << string.to_s if string.present?
  end
end
