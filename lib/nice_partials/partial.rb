module NicePartials
  class Partial
    delegate_missing_to :@view_context

    def initialize(view_context)
      @view_context = view_context
      @content = {}
    end

    def yield(name = nil)
      raise "You can only use Nice Partial's yield method to retrieve the content of named content area blocks. If you're not trying to fetch the content of a named content area block, you don't need Nice Partials! You can just call the vanilla Rails `yield`." unless name
      content_for(name)
    end

    def helpers(&block)
      class_eval &block
    end

    # See the `ActionView::PartialRenderer` monkey patch in `lib/nice_partials/monkey_patch.rb` for something similar.
    def content_for(name, content = nil, &block)
      content = capture(&block) if block

      if content
        @content[name] = ActiveSupport::SafeBuffer.new(content.to_s)
        nil
      else
        @content[name].presence
      end
    end

    def content_for?(name)
      @content[name].present?
    end
  end
end
