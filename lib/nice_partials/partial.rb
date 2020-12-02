module NicePartials
  class Partial
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
  end
end
