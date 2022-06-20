module NicePartials
  class Partial
    delegate_missing_to :@view_context

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

    # See the `ActionView::PartialRenderer` monkey patch in `lib/nice_partials/monkey_patch.rb` for something similar.
    def content_for(name, content = nil, options = {}, &block)
      if block_given?
        partial_prefix = NicePartials.locale_prefix_from_view_context_and_block(@view_context, block)
        @view_context.nice_partials_push_t_prefix(partial_prefix)
      end

      @view_context.content_for("#{name}_#{@key}".to_sym, content, options, &block)
    ensure
      @view_context.nice_partials_pop_t_prefix if block_given?
    end

    def content_for?(name)
      @view_context.content_for?("#{name}_#{@key}".to_sym)
    end
  end
end
