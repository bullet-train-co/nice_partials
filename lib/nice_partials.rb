# frozen_string_literal: true

require_relative "nice_partials/version"
require_relative "nice_partials/helper"
require_relative "nice_partials/monkey_patch"

module NicePartials
  def self.locale_prefix_from_view_context_and_block(context, block)
    root_paths = context.view_renderer.lookup_context.view_paths.map(&:path)
    partial_location = block.source_location.first.dup
    root_paths.each { |path| partial_location.gsub!(/^#{path}\//, '') }
    partial_location.split('.').first.gsub('/_', '/').gsub('/', '.')
  end
end

ActiveSupport.on_load :action_view do
  include NicePartials::Helper
end
