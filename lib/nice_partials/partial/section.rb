# frozen_string_literal: true

class NicePartials::Partial::Section < NicePartials::Partial::Content
  class RequiredError < ArgumentError; end

  class Empty < BasicObject
    def initialize(section)
      @section = section
    end
    delegate :blank?, :present?, :presence, to: :@section

    def nil?
      true
    end

    def method_missing(...)
      present? ? super : ""
    end
  end

  # Returns self if `present?`, or raises.
  # Useful to declare content that you require to be supplied during a `render` call.
  #
  #   <%= partial.title.required.div class: "text-xl" %>
  def required
    present? ? self : raise(RequiredError, "Section expected to have content, but wasn't supplied during render")
  end

  # Returns self if `present?`, or returns a Null object that won't output any content.
  # Useful to declare optional content sections, that you also don't want to print any HTML elements for.
  #
  #   <%= partial.title.optional.div class: "text-xl" %> # => "" # Won't output an empty `<div>` that can mess with HTML markups.
  def optional
    present? ? self : Empty.new(self)
  end

  def yield(*arguments)
    chunks.each { append @view_context.capture(*arguments, &_1) }
    self
  end

  def present?
    chunks.present? || super
  end

  undef_method :p # Remove Kernel.p here to pipe through method_missing and hit tag proxy.

  # Implements our proxying to the `@view_context` or `@view_context.tag`.
  #
  # `@view_context` proxying forwards the message and automatically appends any content, so you can do things like:
  #
  #   <% partial.body.render "form", tangible_thing: @tangible_thing %>
  #   <% partial.body.link_to @document.name, @document %>
  #   <% partial.body.t ".body" %>
  #
  # `@view_context.tag` proxy lets you build bespoke elements based on content and options provided:
  #
  #    <% partial.title "Some title content", class: "xl" %> # Write the content and options to the `title`
  #    <% partial.title.h2 ", appended" %> # => <h2 class="xl">Some title content, appended</h2>
  #
  # Note that NicePartials don't support deep merging attributes out of the box.
  def method_missing(meth, *arguments, **keywords, &block)
    if meth != :p && @view_context.respond_to?(meth)
      append @view_context.public_send(meth, *arguments, **keywords, &block)
    else
      @view_context.tag.public_send(meth, @content + arguments.first.to_s, **options.merge(keywords), &block)
    end
  end

  def respond_to_missing?(...)
    @view_context.respond_to?(...)
  end

  private

  def capture(block)
    if block&.arity&.nonzero?
      chunks << block
    else
      super
    end
  end

  def chunks
    @chunks ||= []
  end
end
