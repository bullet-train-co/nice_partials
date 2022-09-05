class NicePartials::Partial::Options
  module Accessors
    # Contains options passed to a partial:
    #
    #   <% partial.title class: "post-title" %> # partial.title.options # => { class: "post-title" }
    #
    #   # Automatically runs `tag.attributes` when `to_s` is called, e.g.:
    #   <h1 <% partial.title.options %>> # => <h1 class="post-title">
    def options
      @options ||= NicePartials::Partial::Options.new(@view_context)
    end
    delegate :class_list, :data, :aria, to: :options
  end

  class TokenList
    def initialize(view_context)
      @view_context, @content = view_context, +""
    end

    def <<(list)
      @content << " " << @view_context.token_list(list) unless list.empty?
      self
    end

    def to_str
      @content.tap(&:strip!)
    end
    alias to_s to_str
  end

  class Prefixed
    def initialize(view_context, prefix)
      @prefix = "#{prefix}-"
      @values = Hash.new { |h,k| h[k] = TokenList.new(view_context) }
    end

    def merge!(values)
      values.each do |key, value|
        self[key] << value
      end
    end

    def to_h
      @values.transform_keys { prefix + _1 }
    end
  end

  def initialize(view_context)
    @view_context = view_context
    @hash = Hash.new { |h,k| h[k] = TokenList.new(view_context) }
  end
  delegate :tag, :token_list, to: :@view_context
  delegate :to_h, :to_hash, to: :@hash

  def class_list(*arguments)
    @hash[:class] << arguments
  end

  def data(**values)
    @hash[:data] = Prefixed.new(@view_context, :data) unless @hash.key?(:data)
    @hash[:data].merge! values
  end

  def aria(**values)
    @hash[:aria] = Prefixed.new(@view_context, :aria) unless @hash.key?(:aria)
    @hash[:aria].merge! values
  end

  def merge(**options)
    self.class.new(@view_context).merge!(**@hash).merge!(**options)
  end

  def merge!(**options)
    options[:class_list] = options.delete(:class)
    options.each { public_send(_1, _2) }
    self
  end

  def to_s
    tag.attributes(to_h)
  end
end
