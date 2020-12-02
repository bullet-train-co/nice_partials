# frozen_string_literal: true

require_relative "nice_partials/version"
require_relative "nice_partials/helper"
require_relative "partials"

module NicePartials
end

ActionView::Base.send :include, NicePartials::Helper
