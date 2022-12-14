# frozen_string_literal: true

require_relative "nice_partials/version"

module NicePartials
  def self.locale_prefix_from(lookup_context, block)
    partial_location = block.source_location.first.dup
    lookup_context.view_paths.each { partial_location.delete_prefix!(_1.path)&.delete_prefix!("/") }
    partial_location.split('.').first.gsub('/_', '/').gsub('/', '.')
  end
end

ActiveSupport.on_load :action_view do
  require_relative "nice_partials/monkey_patch"

  require_relative "nice_partials/helper"
  include NicePartials::Helper
end
