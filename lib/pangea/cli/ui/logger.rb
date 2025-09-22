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
        
        # Enhanced display methods
        
        # Resource status with enhanced formatting
        def resource_status(resource_type, resource_name, action, status = nil, details = nil)
          # Enhanced symbols and colors
          action_symbol = case action
                         when :create then @pastel.bright_green("◉")
                         when :update then @pastel.bright_yellow("◎")
                         when :delete then @pastel.bright_red("◯")
                         when :replace then @pastel.bright_magenta("⧗")
                         when :import then @pastel.bright_blue("⬇")
                         when :refresh then @pastel.bright_cyan("↻")
                         else @pastel.white("●")
                         end
          
          # Format resource name with type
          resource_display = "#{@pastel.bright_white(resource_type)}.#{@pastel.cyan(resource_name)}"
          
          # Status indicator
          status_indicator = if status
                            case status
                            when :success then @pastel.bright_green(" ✓")
                            when :error then @pastel.bright_red(" ✗")
                            when :warning then @pastel.bright_yellow(" ⚠")
                            when :pending then @pastel.bright_blue(" ⧖")
                            else ""
                            end
                           else
                             ""
                           end
          
          message = "#{action_symbol} #{resource_display}#{status_indicator}"
          message += " #{@pastel.bright_black("(#{details})")}" if details
          
          say message
        end
        
        # Beautiful diff display
        def diff_line(type, content)
          case type
          when :add
            say @pastel.bright_green("+ #{content}")
          when :remove  
            say @pastel.bright_red("- #{content}")
          when :context
            say @pastel.bright_black("  #{content}")
          when :header
            say @pastel.bright_cyan("@@ #{content} @@")
          end
        end
        
        # Template processing status
        def template_status(name, action, duration = nil)
          icon = case action
                when :compiling then "⚙️"
                when :compiled then "✅"
                when :failed then "❌"
                when :validating then "🔍"
                when :validated then "✅"
                else "📄"
                end
          
          message = "#{icon} Template #{@pastel.bright_white(name)}"
          
          case action
          when :compiling
            message += " #{@pastel.yellow('compiling...')}"
          when :compiled
            message += " #{@pastel.green('compiled')}"
            message += " #{@pastel.bright_black("(#{duration}s)")}" if duration
          when :failed
            message += " #{@pastel.red('failed')}"
          when :validating
            message += " #{@pastel.blue('validating...')}"
          when :validated
            message += " #{@pastel.green('validated')}"
          end
          
          say message
        end
        
        # Cost information display
        def cost_info(current: nil, estimated: nil, savings: nil)
          return unless current || estimated || savings
          
          content = ""
          
          if current
            content += "#{@pastel.white('Current')}: #{@pastel.bright_white("$#{current}/month")}\n"
          end
          
          if estimated
            content += "#{@pastel.white('Estimated')}: #{@pastel.bright_white("$#{estimated}/month")}\n"
          end
          
          if savings && savings != 0
            color = savings > 0 ? :bright_green : :bright_red
            symbol = savings > 0 ? "💰" : "⚠️"
            content += "#{symbol} #{@pastel.white('Savings')}: #{@pastel.decorate("$#{savings.abs}/month", color)}\n"
          end
          
          box = TTY::Box.frame(
            content.strip,
            width: 40,
            align: :left,
            border: :light,
            title: {
              top_left: "💰 Cost Impact"
            },
            style: {
              border: {
                color: :yellow
              }
            }
          )
          
          say box
        end
        
        # Time and performance metrics
        def performance_info(metrics)
          content = ""
          
          if metrics[:compilation_time]
            content += "#{@pastel.white('Compilation')}: #{@pastel.bright_white(metrics[:compilation_time])}\n"
          end
          
          if metrics[:planning_time]
            content += "#{@pastel.white('Planning')}: #{@pastel.bright_white(metrics[:planning_time])}\n"
          end
          
          if metrics[:apply_time]
            content += "#{@pastel.white('Apply')}: #{@pastel.bright_white(metrics[:apply_time])}\n"
          end
          
          if metrics[:memory_usage]
            content += "#{@pastel.white('Memory')}: #{@pastel.bright_white(metrics[:memory_usage])}\n"
          end
          
          if metrics[:terraform_version]
            content += "#{@pastel.white('Terraform')}: #{@pastel.bright_white(metrics[:terraform_version])}\n"
          end
          
          return if content.empty?
          
          box = TTY::Box.frame(
            content.strip,
            width: 50,
            align: :left,
            border: :light,
            title: {
              top_left: "⚡ Performance"
            },
            style: {
              border: {
                color: :blue
              }
            }
          )
          
          say box
        end
        
        # Namespace information display
        def namespace_info(namespace_entity)
          content = ""
          content += "#{@pastel.white('Name')}: #{@pastel.bright_white(namespace_entity.name)}\n"
          content += "#{@pastel.white('Backend')}: #{@pastel.bright_white(namespace_entity.state.type)}\n"
          
          case namespace_entity.state.type
          when 's3'
            content += "#{@pastel.white('Bucket')}: #{@pastel.cyan(namespace_entity.state.bucket)}\n"
            content += "#{@pastel.white('Region')}: #{@pastel.cyan(namespace_entity.state.region)}\n"
          when 'local'
            content += "#{@pastel.white('Path')}: #{@pastel.cyan(namespace_entity.state.path)}\n"
          end
          
          if namespace_entity.description
            content += "#{@pastel.white('Description')}: #{@pastel.bright_black(namespace_entity.description)}\n"
          end
          
          box = TTY::Box.frame(
            content.strip,
            width: 60,
            align: :left,
            border: :light,
            title: {
              top_left: "🏷️  Namespace"
            },
            style: {
              border: {
                color: :cyan
              }
            }
          )
          
          say box
        end
        
        # Command completion celebration
        def celebration(message, emoji = "🎉")
          say "\n#{emoji} #{@pastel.bright_green(message)} #{emoji}", color: :bright_green
          say @pastel.bright_black("─" * (message.length + 6))
        end
        
        # Warning panel for important notices
        def warning_panel(title, warnings)
          content = @pastel.bright_yellow("⚠️  #{title}") + "\n\n"
          
          warnings.each do |warning|
            content += "#{@pastel.yellow('•')} #{@pastel.white(warning)}\n"
          end
          
          box = TTY::Box.frame(
            content.strip,
            width: 70,
            align: :left,
            border: :thick,
            style: {
              border: {
                color: :yellow
              }
            }
          )
          
          say box
        end
      end
    end
  end
end