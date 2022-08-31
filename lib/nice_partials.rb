# frozen_string_literal: true

require_relative "nice_partials/version"

module NicePartials
  singleton_class.attr_accessor :options_processor
  self.options_processor = ->(options, new_options) { options.merge! new_options }

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
