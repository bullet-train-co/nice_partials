module NicePartials
  class Partial
    def initialize(view_context, *names)
      @view_context = view_context
      names.each { |name| generate_attribute_methods(name) }
    end

    def yield(name = nil)
      raise "You can only use Nice Partial's yield method to retrieve the content of named content area blocks. If you're not trying to fetch the content of a named content area block, you don't need Nice Partials! You can just call the vanilla Rails `yield`." unless name
      public_send(name)
    end

    def helpers(&block)
      class_eval &block
    end

    # See the `ActionView::PartialRenderer` monkey patch in `lib/nice_partials/monkey_patch.rb` for something similar.
    def content_for(name, content = nil, &block)
      public_send(name, content, &block)
    end

    def content_for?(name)
      public_send(name).present?
    end

    def respond_to_missing?(meth, *args, **options, &block)
      @view_content.respond_to?(meth, *args, **options, &block)
    end

    def method_missing(meth, *args, **options, &block)
      if @view_context.respond_to?(meth)
        @view_context.send(meth, *args, **options, &block)
      else
        generate_attribute_methods meth.to_s.sub(/(\?|=)/, "")
        public_send(meth, *args, **options, &block)
      end
    end

    private

    def generate_attribute_methods(name)
      self.class.class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{name}(content = nil, **options, &block)
          options, content = content, nil if content.is_a?(Hash) # lol Ruby 3 keywords

          if content || options.any? || block
            self.#{name} = Section.new(content || (@view_context.capture(&block) if block), **options)
            nil
          else
            @#{name}.presence
          end
        end

        def #{name}=(content)
          @#{name} = Section.wrap(content)
        end

        def #{name}?
          @#{name}.present?
        end
      RUBY
    end

    class Section
      attr_reader :content, :options
      delegate :to_s, to: :content

      def self.wrap(section)
        section.is_a?(self) ? section : new(section)
      end

      def initialize(content, **options)
        @content = content.present? ? ActiveSupport::SafeBuffer.new(content.to_s) : content.to_s
        @options = options
      end

      def with(**options)
        @options.merge!(**options)
        self
      end
    end
  end
end
