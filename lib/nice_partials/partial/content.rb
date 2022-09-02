class NicePartials::Partial::Content
  def initialize(view_context)
    @view_context, @content = view_context, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, :present?, to: :@content

  def options
    @options ||= {}
  end

  def write?(content = nil, **new_options, &block)
    process_options new_options
    append content or capture block
  end

  def write(...)
    write?(...)
    self
  end

  private

  def process_options(new_options)
    @options = NicePartials.options_processor.call(options, new_options) unless new_options.empty?
  end

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
