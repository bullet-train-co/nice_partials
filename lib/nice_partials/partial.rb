module NicePartials
  class Partial
    autoload :Content, "nice_partials/partial/content"
    autoload :Section, "nice_partials/partial/section"
    autoload :Stack, "nice_partials/partial/stack"

    delegate_missing_to :@view_context

    #   <%= render "nice_partial" do |p| %>
    #     <% p.content_for :title, "Yo" %>
    #     This content can be accessed through calling `yield`.
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
        output_buffer
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
    def section(name, content = nil, &block)
      section_from(name).process(content, block)
    end
    alias content_for section

    def section?(name)
      @sections&.dig(name).present?
    end
    alias content_for? section?

    def capture(*arguments, &block)
      self.output_buffer = @view_context.capture(*arguments, self, &block)
    end

    private

    def section_from(name)
      @sections ||= {} and @sections[name] ||= Section.new(@view_context)
    end

    def method_missing(meth, *arguments, **keywords, &block)
      if @view_context.respond_to?(meth)
        @view_context.public_send(meth, *arguments, **keywords, &block)
      else
        define_accessor meth and public_send meth
      end
    end

    def define_accessor(name)
      name = name.to_s.chomp("?").to_sym
      self.class.define_method(name) { section_from(name) }
      self.class.define_method("#{name}?") { section?(name) }
    end
  end
end
