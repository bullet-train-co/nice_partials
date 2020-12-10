module NicePartials
  class Partial
    DEFAULT_CONTENT_FOR_OPTIONS = [:flush]

    delegate_missing_to :@view_context

    def initialize(view_context)
      @view_context = view_context
      @key = SecureRandom.uuid
      @content_options = {}
    end

    def yield(name = nil)
      raise "You can only use Nice Partial's yield method to retrieve the content of named content area blocks. If you're not trying to fetch the content of a named content area block, you don't need Nice Partials! You can just call the vanilla Rails `yield`." unless name
      content_for(name)
    end

    def helpers(&block)
      class_eval &block
    end

    def content_for(name, content = nil, options = {}, &block)
      if content || block_given?
        if block_given?
          options = content || {}
          content = @view_context.capture(&block)
        end

        options_for(name, options.without(*DEFAULT_CONTENT_FOR_OPTIONS))
      end

      @view_context.content_for(name_for(name), content, options.slice(*DEFAULT_CONTENT_FOR_OPTIONS))
    end

    def content_for?(name)
      @view_context.content_for?(name_for(name))
    end

    def options_for(name, options = nil)
      if options
        @content_options[name_for(name)] = options
        nil
      else
        @content_options[name_for(name)] || {}
      end
    end

    def name_for(name)
      "#{name}_#{@key}".to_sym
    end
  end
end
