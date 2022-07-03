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
      @key = SecureRandom.uuid
    end

    def yield(name = nil)
      raise "You can only use Nice Partial's yield method to retrieve the content of named content area blocks. If you're not trying to fetch the content of a named content area block, you don't need Nice Partials! You can just call the vanilla Rails `yield`." unless name
      content_for(name)
    end

    def helpers(&block)
      class_eval &block
    end

    def content_for(name, content = nil, options = {}, &block)
      @view_context.content_for("#{name}_#{@key}".to_sym, content, options, &block)
    end

    def content_for?(name)
      @view_context.content_for?("#{name}_#{@key}".to_sym)
    end

    def capture(block)
      if block&.arity == 1
        # Mimic standard `yield` by calling into `_layout_for` directly.
        self.output_buffer = @view_context._layout_for(self, &block)
      end
    end
  end
end
