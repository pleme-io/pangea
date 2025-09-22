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
        # Style configuration for log levels
        LOG_STYLES = {
          info:    { symbol: "ℹ",  label: "info",    color: :bright_blue,   levelpad: 1 },
          success: { symbol: "✓", label: "success", color: :bright_green,  levelpad: 0 },
          error:   { symbol: "✗", label: "error",   color: :bright_red,    levelpad: 1 },
          warn:    { symbol: "⚠",  label: "warning", color: :bright_yellow, levelpad: 0 },
          debug:   { symbol: "•", label: "debug",   color: :bright_black,  levelpad: 1 }
        }.freeze
        
        # Action symbols and colors mapping
        ACTION_STYLES = {
          create:  { symbol: "◉", color: :bright_green },
          update:  { symbol: "◎", color: :bright_yellow },
          delete:  { symbol: "◯", color: :bright_red },
          replace: { symbol: "⧗", color: :bright_magenta },
          import:  { symbol: "⬇", color: :bright_blue },
          refresh: { symbol: "↻", color: :bright_cyan },
          default: { symbol: "●", color: :white }
        }.freeze
        
        # Status indicators mapping
        STATUS_INDICATORS = {
          success: " ✓",
          error:   " ✗",
          warning: " ⚠",
          pending: " ⧖"
        }.freeze
        
        # Template action icons
        TEMPLATE_ICONS = {
          compiling:  "⚙️",
          compiled:   "✅",
          failed:     "❌",
          validating: "🔍",
          validated:  "✅",
          default:    "📄"
        }.freeze
        
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
          say "\n━━━ #{title} ━━━", color: :bright_cyan
        end
        
        # Resource actions
        def resource_action(action, resource_type, resource_name, status = nil)
          symbols = { create: "+", update: "~", delete: "-", replace: "±" }
          colors = { create: :bright_green, update: :bright_yellow, delete: :bright_red, replace: :bright_magenta }
          
          action_symbol = symbols[action] || "?"
          action_color = colors[action] || :white
          
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
          action_texts = { create: "Creating", update: "Updating", delete: "Deleting", read: "Reading" }
          action_text = action_texts[action] || action.to_s.capitalize
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
          style = ACTION_STYLES[action] || ACTION_STYLES[:default]
          action_symbol = @pastel.decorate(style[:symbol], style[:color])
          
          resource_display = "#{@pastel.bright_white(resource_type)}.#{@pastel.cyan(resource_name)}"
          
          status_indicator = if status && indicator = STATUS_INDICATORS[status]
                              color = status == :success ? :bright_green : 
                                     status == :error ? :bright_red :
                                     status == :warning ? :bright_yellow : :bright_blue
                              @pastel.decorate(indicator, color)
                            else
                              ""
                            end
          
          message = "#{action_symbol} #{resource_display}#{status_indicator}"
          message += " #{@pastel.bright_black("(#{details})")}" if details
          
          say message
        end
        
        # Beautiful diff display
        def diff_line(type, content)
          diff_styles = {
            add:     { prefix: "+ ", color: :bright_green },
            remove:  { prefix: "- ", color: :bright_red },
            context: { prefix: "  ", color: :bright_black },
            header:  { prefix: "@@ ", suffix: " @@", color: :bright_cyan }
          }
          
          style = diff_styles[type]
          return unless style
          
          formatted_content = style[:suffix] ? "#{content}#{style[:suffix]}" : content
          say @pastel.decorate("#{style[:prefix]}#{formatted_content}", style[:color])
        end
        
        # Template processing status
        def template_status(name, action, duration = nil)
          icon = TEMPLATE_ICONS[action] || TEMPLATE_ICONS[:default]
          
          action_texts = {
            compiling:  { text: 'compiling...', color: :yellow },
            compiled:   { text: 'compiled', color: :green },
            failed:     { text: 'failed', color: :red },
            validating: { text: 'validating...', color: :blue },
            validated:  { text: 'validated', color: :green }
          }
          
          message = "#{icon} Template #{@pastel.bright_white(name)}"
          
          if action_info = action_texts[action]
            message += " #{@pastel.decorate(action_info[:text], action_info[:color])}"
            message += " #{@pastel.bright_black("(#{duration}s)")}" if duration && action == :compiled
          end
          
          say message
        end
        
        # Cost information display
        def cost_info(current: nil, estimated: nil, savings: nil)
          return unless current || estimated || savings
          
          content = build_content do |c|
            c << "#{@pastel.white('Current')}: #{@pastel.bright_white("$#{current}/month")}" if current
            c << "#{@pastel.white('Estimated')}: #{@pastel.bright_white("$#{estimated}/month")}" if estimated
            
            if savings && savings != 0
              color = savings > 0 ? :bright_green : :bright_red
              symbol = savings > 0 ? "💰" : "⚠️"
              c << "#{symbol} #{@pastel.white('Savings')}: #{@pastel.decorate("$#{savings.abs}/month", color)}"
            end
          end
          
          display_box(content, title: "💰 Cost Impact", color: :yellow, width: 40)
        end
        
        # Time and performance metrics
        def performance_info(metrics)
          metric_labels = {
            compilation_time: 'Compilation',
            planning_time:    'Planning',
            apply_time:       'Apply',
            memory_usage:     'Memory',
            terraform_version: 'Terraform'
          }
          
          content = build_content do |c|
            metric_labels.each do |key, label|
              c << "#{@pastel.white(label)}: #{@pastel.bright_white(metrics[key])}" if metrics[key]
            end
          end
          
          return if content.empty?
          display_box(content, title: "⚡ Performance", color: :blue, width: 50)
        end
        
        # Namespace information display
        def namespace_info(namespace_entity)
          content = build_content do |c|
            c << "#{@pastel.white('Name')}: #{@pastel.bright_white(namespace_entity.name)}"
            c << "#{@pastel.white('Backend')}: #{@pastel.bright_white(namespace_entity.state.type)}"
            
            case namespace_entity.state.type
            when 's3'
              c << "#{@pastel.white('Bucket')}: #{@pastel.cyan(namespace_entity.state.bucket)}"
              c << "#{@pastel.white('Region')}: #{@pastel.cyan(namespace_entity.state.region)}"
            when 'local'
              c << "#{@pastel.white('Path')}: #{@pastel.cyan(namespace_entity.state.path)}"
            end
            
            if namespace_entity.description
              c << "#{@pastel.white('Description')}: #{@pastel.bright_black(namespace_entity.description)}"
            end
          end
          
          display_box(content, title: "🏷️  Namespace", color: :cyan, width: 60)
        end
        
        # Command completion celebration
        def celebration(message, emoji = "🎉")
          say "\n#{emoji} #{@pastel.bright_green(message)} #{emoji}", color: :bright_green
          say @pastel.bright_black("─" * (message.length + 6))
        end
        
        # Warning panel for important notices
        def warning_panel(title, warnings)
          content = @pastel.bright_yellow("⚠️  #{title}") + "\n\n"
          content += warnings.map { |w| "#{@pastel.yellow('•')} #{@pastel.white(w)}" }.join("\n")
          
          display_box(content, color: :yellow, width: 70, border: :thick)
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