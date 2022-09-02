# frozen_string_literal: true

require_relative "nice_partials/version"

begin
  gem "attributes_and_token_lists"
  require "attributes_and_token_lists/attributes"
rescue LoadError
end

module NicePartials
  class Options < Hash
    attr_accessor :tag

    def to_s
      @tag.attributes(self)
    end
  end

  singleton_class.attr_accessor :new_options
  self.new_options =
    if defined?(AttributesAndTokenLists::Attributes)
      -> view_context { AttributesAndTokenLists::Attributes.new(view_context.tag, view_context) }
    else
      -> view_context { Options.new.tap { _1.tag = view_context.tag } }
    end

  def self.locale_prefix_from(lookup_context, block)
    root_paths = lookup_context.view_paths.map(&:path)
    partial_location = block.source_location.first.dup
    root_paths.each { |path| partial_location.gsub!(/^#{path}\//, '') }
    partial_location.split('.').first.gsub('/_', '/').gsub('/', '.')
  end
end

ActiveSupport.on_load :action_view do
  require_relative "nice_partials/monkey_patch"

  require_relative "nice_partials/helper"
  include NicePartials::Helper
end
