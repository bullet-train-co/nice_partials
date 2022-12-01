class NicePartials::Partial::Content
  class Options < Hash
    def initialize(view_context)
      @view_context = view_context
    end

    def to_s
      @view_context.tag.attributes(self)
    end
  end

  def initialize(view_context, content = nil)
    @view_context, @options = view_context, Options.new(view_context)
    @content = ActiveSupport::SafeBuffer.new and concat content
  end
  delegate :to_s, :present?, to: :@content

  # Contains options passed to a partial:
  #
  #   <% partial.title class: "post-title" %> # partial.title.options # => { class: "post-title" }
  #
  #   # Automatically runs `tag.attributes` when `to_s` is called, e.g.:
  #   <h1 <% partial.title.options %>> # => <h1 class="post-title">
  attr_reader :options

  def write?(content = nil, **new_options, &block)
    @options.merge! new_options
    append content or capture block
  end

  def write(...)
    write?(...)
    self
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
