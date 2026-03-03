# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'

module Pangea
  module CLI
    module UI
      class Logger
        # Style configuration for log levels
        module Styles
          LOG_STYLES       = Boreal::Components::Logger.log_styles
          ACTION_STYLES    = Boreal::Components::Logger.action_styles
          STATUS_INDICATORS = Boreal::Components::Logger.status_indicators
          TEMPLATE_ICONS   = Boreal::Components::Logger.template_icons
        end
      end
    end
  end
end
