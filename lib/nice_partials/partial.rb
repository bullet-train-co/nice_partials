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

    def yield(name = nil)
      raise "You can only use Nice Partial's yield method to retrieve the content of named content area blocks. If you're not trying to fetch the content of a named content area block, you don't need Nice Partials! You can just call the vanilla Rails `yield`." unless name
      content_for(name)
    end

    def helpers(&block)
      class_eval &block
    end

    def content_for(name, content = nil, &block)
      content = @view_context.capture(&block) if block

      if content
        contents[name] << content.to_s
        nil
      else
        contents[name].presence
      end
    end

    def content_for?(name)
      contents[name].present?
    end

    def capture(*arguments, &block)
      self.output_buffer = @view_context.capture(*arguments, self, &block)
    end

    private

    def contents
      @contents ||= Hash.new { |h, k| h[k] = ActiveSupport::SafeBuffer.new }
    end
  end
end
