# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'pastel'
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
          @pastel = Pastel.new
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

        # Direct output with color
        def say(message, color: nil)
          if color
            puts @pastel.decorate(message, color)
          else
            puts message
          end
        end

        # Section headers
        def section(title)
          say "\n--- #{title} ---", color: :bright_cyan
        end

        # Expose pastel for advanced formatting
        def pastel
          @pastel
        end

        private

        # Build content string from blocks
        def build_content
          lines = []
          yield(lines)
          lines.join("\n")
        end

        # Display a framed box
        def display_box(content, title: nil, color: :white, width: 50, border: :light)
          options = {
            width: width,
            align: :left,
            border: border,
            style: { border: { color: color } }
          }

          options[:title] = { top_left: title } if title

          say TTY::Box.frame(content.strip, **options)
        end
      end
    end
  end
end
