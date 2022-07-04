module NicePartials
  class Partial
    delegate_missing_to :@view_context

    #   <%= render "nice_partial" do |p| %>
    #     <% p.content_for :title, "Yo" %>
    #     This line is printed to the `output_buffer`.
    #   <% end %>
    #
    # Then in the nice_partial:
    #   <%= content.content_for :title %> # => "Yo"
    #   <%= content.output_buffer %> # => "This line is printed to the `output_buffer`."
    attr_accessor :output_buffer

    def initialize(view_context)
      @view_context = view_context
    end

    def yield(*arguments, &block)
      if arguments.empty?
        raise "You can only use Nice Partial's yield method to retrieve the content of named content area blocks. If you're not trying to fetch the content of a named content area block, you don't need Nice Partials! You can just call the vanilla Rails `yield`."
      else
        content_for(*arguments, &block)
      end
    end

    def helpers(&block)
      class_eval &block
    end

    # Similar to Rails' built-in `content_for` except it defers any block execution
    # and lets you pass arguments into it, like so:
    #
    #   # Here we store a block with some eventual content…
    #   <% partial.content_for :title do |tag|
    #     <%= tag.h1 %>
    #   <% end %>
    #
    #  # …which is then invoked with some predefined options later.
    #  <%= partial.content_for :title, tag.with_options(class: "text-bold") %>
    def content_for(name, content = nil, *arguments, &block)
      contents[name].content_for(content, *arguments, &block)
    end

    def content_for?(name)
      contents[name].content?
    end

    def capture(block)
      if block&.arity == 1
        # Mimic standard `yield` by calling into `_layout_for` directly.
        self.output_buffer = @view_context._layout_for(self, &block)
      end
    end

    private

    class Section
      def initialize(view_context)
        @view_context = view_context
        @pending_content = nil
        @content = ActiveSupport::SafeBuffer.new
      end

      def content_for(*arguments, &block)
        if write_content_for(arguments.first, &block)
          nil
        else
          capture_content_for(*arguments) if @pending_content
          @content.presence
        end
      end

      def content?
        @pending_content.present? || @content.present?
      end

      private

      def write_content_for(content = nil, &block)
        @content << content.to_s if content && !@pending_content
        @pending_content = block if block
      end

      def capture_content_for(*arguments)
        @content << @view_context.capture(*arguments, &@pending_content).to_s
        @pending_content = nil
      end
    end

    def contents
      @contents ||= Hash.new { |h, k| h[k] = Section.new(@view_context) }
    end
  end
end
