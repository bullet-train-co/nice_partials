class NicePartials::Partial::Content
  autoload :Options, "nice_partials/partial/content/options"

  def initialize(view_context)
    @view_context, @content = view_context, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, :present?, to: :@content

  # Contains options passed to a partial:
  #
  #   <% partial.title class: "post-title" %> # partial.title.options # => { class: "post-title" }
  #
  #   # Automatically runs `tag.attributes` when `to_s` is called, e.g.:
  #   <h1 <% partial.title.options %>> # => <h1 class="post-title">
  def options
    @options ||= Options.new(@view_context)
  end
  delegate :class_list, :data, :aria, to: :options

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
    options.merge!(**new_options) unless new_options.empty?
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
