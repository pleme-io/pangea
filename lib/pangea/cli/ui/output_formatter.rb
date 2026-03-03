# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'tty-box'
require 'tty-table'
require_relative 'output_formatter/constants'
require_relative 'output_formatter/formatting'
require_relative 'output_formatter/display'

module Pangea
  module CLI
    module UI
      # Unified output formatter for consistent, beautiful CLI output.
      # All color output uses Boreal (Nord-themed 24-bit true color).
      class OutputFormatter
        include Formatting
        include Display
      end
    end
  end
end
