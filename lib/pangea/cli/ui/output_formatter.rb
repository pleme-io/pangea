# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pastel'
require 'tty-box'
require 'tty-table'
require_relative 'output_formatter/constants'
require_relative 'output_formatter/formatting'
require_relative 'output_formatter/display'

module Pangea
  module CLI
    module UI
      # Unified output formatter for consistent, beautiful CLI output
      class OutputFormatter
        include Formatting
        include Display

        attr_reader :pastel

        def initialize
          @pastel = Pastel.new
        end
      end
    end
  end
end
