# frozen_string_literal: true

require_relative "nice_partials/version"

module NicePartials
end

ActiveSupport.on_load :action_view do
  require_relative "nice_partials/monkey_patch"

  require_relative "nice_partials/helper"
  include NicePartials::Helper
end
