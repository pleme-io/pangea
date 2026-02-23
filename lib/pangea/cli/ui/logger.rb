# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'tty-logger'
require 'tty-box'

require_relative 'logger/styles'
require_relative 'logger/resource_display'
require_relative 'logger/info_panels'
require_relative 'logger/display_helpers'

module Pangea
  module CLI
    module UI
      # Beautiful logging with colors and formatting
      class Logger
        include Styles
        include ResourceDisplay
        include InfoPanels
        include DisplayHelpers

        def initialize
          @logger = TTY::Logger.new do |config|
            config.handlers = [
              [:console, { styles: LOG_STYLES }]
            ]
          end
        end

        # Standard log levels
        %i[info success error warn].each do |level|
          define_method(level) do |message, **metadata|
            @logger.send(level, message, **metadata)
          end
        end

        def debug(message, **metadata)
          @logger.debug(message, **metadata) if ENV['DEBUG']
        end

        # Direct output with color (uses Boreal roles for 24-bit Nord colors)
        def say(message, color: nil)
          if color
            puts Boreal.paint(message, color)
          else
            puts message
          end
        end

        # Section headers
        def section(title)
          say "\n--- #{title} ---", color: :primary
        end

        private

        # Build content string from blocks
        def build_content
          lines = []
          yield(lines)
          lines.join("\n")
        end

        # Display a framed box
        def display_box(content, title: nil, color: :text, width: 50, border: :light)
          pastel_color = Boreal::Compat::PASTEL_MAP[color] || color
          options = {
            width: width,
            align: :left,
            border: border,
            style: { border: { color: pastel_color } }
          }

          options[:title] = { top_left: title } if title

          say TTY::Box.frame(content.strip, **options)
        end
      end
    end
  end
end
