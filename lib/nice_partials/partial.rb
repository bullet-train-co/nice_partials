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
      if block_given?
        @partial_prefix = caller.detect { |line| line.include?('app/views') }.split('.').first.gsub(Rails.root.to_s + '/app/views/', '').gsub('/_', '/').gsub('/', '.')
        @view_context.nice_partials_push_t_prefix(@partial_prefix)
      end

      result = @view_context.content_for("#{name}_#{@key}".to_sym, content, options, &block)

      if block_given?
        @view_context.nice_partials_pop_t_prefix
      end

      return result
    end

    def content_for?(name)
      @view_context.content_for?("#{name}_#{@key}".to_sym)
    end
  end
end
