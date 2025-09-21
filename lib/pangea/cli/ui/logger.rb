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

module Pangea
  module CLI
    module UI
      # Beautiful logging with colors and formatting
      class Logger
        def initialize
          @pastel = Pastel.new
          @logger = TTY::Logger.new do |config|
            config.handlers = [
              [:console, {
                styles: {
                  info: {
                    symbol: "ℹ",
                    label: "info",
                    color: :bright_blue,
                    levelpad: 1
                  },
                  success: {
                    symbol: "✓",
                    label: "success",
                    color: :bright_green,
                    levelpad: 0
                  },
                  error: {
                    symbol: "✗",
                    label: "error",
                    color: :bright_red,
                    levelpad: 1
                  },
                  warn: {
                    symbol: "⚠",
                    label: "warning",
                    color: :bright_yellow,
                    levelpad: 0
                  },
                  debug: {
                    symbol: "•",
                    label: "debug",
                    color: :bright_black,
                    levelpad: 1
                  }
                }
              }]
            ]
          end
        end
        
        # Standard log levels
        def info(message, **metadata)
          @logger.info(message, **metadata)
        end
        
        def success(message, **metadata)
          @logger.success(message, **metadata)
        end
        
        def error(message, **metadata)
          @logger.error(message, **metadata)
        end
        
        def warn(message, **metadata)
          @logger.warn(message, **metadata)
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
          say "\n━━━ #{title} ━━━", color: :bright_cyan
        end
        
        # Resource actions
        def resource_action(action, resource_type, resource_name, status = nil)
          action_symbol = case action
                         when :create then "+"
                         when :update then "~"
                         when :delete then "-"
                         when :replace then "±"
                         else "?"
                         end
          
          action_color = case action
                        when :create then :bright_green
                        when :update then :bright_yellow
                        when :delete then :bright_red
                        when :replace then :bright_magenta
                        else :white
                        end
          
          message = "#{action_symbol} #{resource_type}.#{resource_name}"
          
          if status
            status_color = status == :success ? :green : :red
            status_text = status == :success ? "✓" : "✗"
            message += " #{@pastel.decorate(status_text, status_color)}"
          end
          
          say message, color: action_color
        end
        
        # Progress messages
        def step(number, total, message)
          say "[#{number}/#{total}] #{message}", color: :bright_black
        end
        
        # File operations
        def file_action(action, path)
          action_text = case action
                       when :create then "Creating"
                       when :update then "Updating"
                       when :delete then "Deleting"
                       when :read then "Reading"
                       else action.to_s.capitalize
                       end
          
          info "#{action_text} #{path}"
        end
        
        # Code display
        def code(content, language: :ruby)
          say "```#{language}", color: :bright_black
          say content
          say "```", color: :bright_black
        end
        
        # Error context
        def error_context(error, file: nil, line: nil)
          error "#{error.class}: #{error.message}"
          
          if file && line
            say "  Location: #{file}:#{line}", color: :bright_black
          end
          
          if ENV['DEBUG'] && error.backtrace
            say "\nBacktrace:", color: :bright_black
            error.backtrace.first(10).each do |frame|
              say "  #{frame}", color: :bright_black
            end
          end
        end
        
        # Expose pastel for advanced formatting
        def pastel
          @pastel
        end
      end
    end
  end
end