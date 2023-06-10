module NicePartials
  class Partial
    autoload :Content, "nice_partials/partial/content"
    autoload :Section, "nice_partials/partial/section"
    autoload :Stack, "nice_partials/partial/stack"

    attr_reader :local_assigns
    alias_method :locals, :local_assigns

    def initialize(view_context, local_assigns = nil)
      @view_context, @local_assigns = view_context, local_assigns
    end

    def yield(*arguments, &block)
      if arguments.empty?
        @captured_buffer
      else
        content_for(*arguments, &block)
      end
    end

    def helpers(&block)
      Helpers.class_eval(&block)
    end

    # `translate` is a shorthand to set `content_for` with content that's run through
    # the view's `translate`/`t` context.
    #
    #   partial.t :title                       # => partial.content_for :title, t(".title")
    #   partial.t title: :section              # => partial.content_for :title, t(".section")
    #   partial.t title: "some.custom.key"     # => partial.content_for :title, t("some.custom.key")
    #   partial.t :description, title: :header # Mixing is supported too.
    #
    # Note that `partial.t "some.custom.key"` can't derive a `content_for` name, so an explicit
    # name must be provided e.g. `partial.t title: "some.custom.key"`.
    def translate(*names, **renames)
      names.chain(renames).each do |name, key = name|
        content_for name, @view_context.t(key.is_a?(String) ? key : ".#{key}")
      end
    end
    alias t translate

    # Allows an inner partial to copy content from an outer partial.
    #
    # Additionally a hash of keys to rename in the new partial context can be passed.
    #
    #   First, an outer partial gets some content set:
    #   <% partial.title "Hello there" %>
    #   <% partial.byline "Somebody" %>
    #
    #   Second, a new partial is rendered, but we want to extract the title, byline content but rename the byline key too:
    #   <%= render "shared/title" do |cp| %>
    #     <% cp.content_from partial, :title, byline: :name %>
    #   <% end %>
    #
    #   # Third, the contents with any renames are accessible in shared/_title.html.erb:
    #   <%= partial.title %> # => "Hello there"
    #   <%= partial.name %> # => "Somebody"
    def content_from(partial, *names, **renames)
      names.chain(renames).each { |key, new_key = key| public_send new_key, partial.public_send(key).to_s }
    end

    # Similar to Rails' built-in `content_for` except it defers any block execution
    # and lets you pass arguments into it, like so:
    #
    #   # Here we store a block with some eventual content…
    #   <% partial.title { |tag| tag.h1 } %>
    #
    #  # …which we can then yield into with some predefined options later.
    #  <%= partial.title.yield tag.with_options(class: "text-bold") %>
    def section(name, content = nil, **options, &block)
      section_from(name).then { _1.write?(content, **options, &block) ? nil : _1 }
    end

    def section?(name)
      section_from(name).present?
    end
    alias content_for? section?

    def content_for(...)
      section(...).presence&.to_s
    end

    def slice(*keys)
      keys.index_with { content_for _1 }
    end

    def capture(*arguments, &block)
      @captured_buffer = @view_context.capture(*arguments, self, &block)
    end

    private

    def section_from(name)
      @sections ||= {} and @sections[name] ||= Section.new(@view_context, @local_assigns&.dig(name))
    end

    def respond_to_missing?(meth, include_private = false)
      meth != :to_ary # Avoid creating a section when doing `*partial`.
    end

    def method_missing(meth, *arguments, **keywords, &block)
      define_accessor meth and public_send(meth, *arguments, **keywords, &block)
    end

    def define_accessor(name)
      name = name.to_s.chomp("?").to_sym
      self.class.define_method(name) { |content = nil, **options, &block| section(name, content, **options, &block) }
      self.class.define_method("#{name}?") { section?(name) }
    end

    def helpers_context
      @helpers_context ||= Helpers.new(@view_context, self)
    end

    class Helpers < SimpleDelegator
      def self.method_added(name)
        super

        unless name == :initialize || name == :partial
          NicePartials::Partial.delegate name, to: :helpers_context
        end
      end

      attr_reader :partial

      def initialize(view_context, partial)
        super(view_context)
        @partial = partial
      end
    end
  end
end
