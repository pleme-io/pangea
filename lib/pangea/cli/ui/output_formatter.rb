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
require 'tty-box'
require 'tty-table'
require 'json'

module Pangea
  module CLI
    module UI
      # Unified output formatter for consistent, beautiful CLI output
      class OutputFormatter
        # Design system constants
        ICONS = {
          # Status indicators
          success: '✓',
          error: '✗',
          warning: '⚠',
          info: 'ℹ',
          pending: '⧖',

          # Action indicators
          create: '+',
          update: '~',
          delete: '-',
          replace: '±',
          import: '⬇',
          refresh: '↻',

          # Resource types
          template: '📄',
          resource: '🏗️',
          provider: '☁️',
          backend: '🔧',
          namespace: '🏷️',
          workspace: '📁',
          config: '⚙️',
          summary: '📊',
          plan: '📋',
          output: '📤',
          state: '📈',
          diff: '🔄',
          security: '🔒',
          network: '🌐',
          database: '🗄️',
          compute: '💻',
          storage: '💾',

          # Process indicators
          compiling: '⚙️',
          compiled: '✅',
          failed: '❌',
          validating: '🔍',
          validated: '✅',
          applying: '🚀',
          destroying: '💥',
          initializing: '🔧'
        }.freeze

        COLORS = {
          # Status colors
          success: :green,
          error: :red,
          warning: :yellow,
          info: :blue,
          pending: :cyan,

          # Action colors
          create: :green,
          update: :yellow,
          delete: :red,
          replace: :magenta,

          # Emphasis colors
          primary: :cyan,
          secondary: :bright_cyan,
          muted: :bright_black,
          highlight: :bright_white,

          # Resource colors
          resource_type: :cyan,
          resource_name: :bright_white,
          attribute_key: :white,
          attribute_value: :bright_black
        }.freeze

        attr_reader :pastel

        def initialize
          @pastel = Pastel.new
        end

        # Section headers with consistent styling
        def section_header(title, icon: nil, width: 60)
          full_title = icon ? "#{ICONS[icon]} #{title}" : title
          divider = '━' * width

          puts
          puts @pastel.cyan(divider)
          puts @pastel.bold(@pastel.cyan(full_title))
          puts @pastel.cyan(divider)
          puts
        end

        # Subsection headers
        def subsection_header(title, icon: nil)
          full_title = icon ? "#{ICONS[icon]}  #{title}:" : "#{title}:"
          puts @pastel.bold(full_title)
        end

        # Status message with icon and color
        def status(type, message, details: nil)
          icon = ICONS[type]
          color = COLORS[type]

          line = "#{icon} #{message}"
          puts @pastel.decorate(line, color)

          if details
            details.each do |key, value|
              puts "  #{@pastel.white(key)}: #{@pastel.bright_black(value)}"
            end
          end
        end

        # Key-value pair display
        def kv_pair(key, value, indent: 2)
          spaces = ' ' * indent
          formatted_value = format_value(value)
          puts "#{spaces}#{@pastel.white(key)}: #{formatted_value}"
        end

        # List of items with bullets
        def list_items(items, icon: '•', color: :white, indent: 2)
          spaces = ' ' * indent
          items.each do |item|
            puts "#{spaces}#{@pastel.decorate(icon, color)} #{item}"
          end
        end

        # Resource display with type and name
        def resource(type, name, attributes: {}, indent: 2)
          spaces = ' ' * indent
          full_name = "#{type}.#{name}"
          puts "#{spaces}• #{@pastel.decorate(full_name, :bold)}"

          if attributes.any?
            attributes.each do |key, value|
              formatted_value = format_value(value)
              puts "#{spaces}  #{key}: #{@pastel.bright_black(formatted_value)}"
            end
          end
        end

        # Resource change display with action
        def resource_change(action, type, name, attributes: {}, indent: 2)
          spaces = ' ' * indent
          icon = ICONS[action]
          color = COLORS[action]
          full_name = "#{type}.#{name}"

          puts "#{spaces}#{@pastel.decorate(icon, color)} #{@pastel.bold(full_name)}"

          if attributes.any?
            attributes.each do |key, value|
              formatted_value = format_value(value)
              puts "#{spaces}  #{key}: #{@pastel.bright_black(formatted_value)}"
            end
          end
        end

        # Table display
        def table(headers, rows, title: nil)
          puts
          puts @pastel.bold(title) if title

          table = TTY::Table.new(headers, rows)
          renderer = table.render(:unicode, padding: [0, 1])
          puts renderer
          puts
        end

        # Info box
        def info_box(title, content, width: 60)
          box = TTY::Box.frame(
            width: width,
            title: { top_left: title },
            border: :light,
            padding: 1,
            style: {
              border: { fg: :cyan }
            }
          ) do
            content
          end

          puts box
        end

        # Warning box
        def warning_box(title, warnings, width: 60)
          content = warnings.map { |w| "#{ICONS[:warning]} #{w}" }.join("\n")

          box = TTY::Box.frame(
            width: width,
            title: { top_left: "⚠️  #{title}" },
            border: :thick,
            padding: 1,
            style: {
              border: { fg: :yellow }
            }
          ) do
            content
          end

          puts box
        end

        # Error box
        def error_box(title, errors, width: 60)
          content = errors.map { |e| "#{ICONS[:error]} #{e}" }.join("\n")

          box = TTY::Box.frame(
            width: width,
            title: { top_left: "❌ #{title}" },
            border: :thick,
            padding: 1,
            style: {
              border: { fg: :red }
            }
          ) do
            content
          end

          puts box
        end

        # Success banner
        def success_banner(message, width: 60)
          divider = '━' * width

          puts
          puts @pastel.green(divider)
          puts @pastel.bold(@pastel.green("#{ICONS[:success]} #{message}"))
          puts @pastel.green(divider)
          puts
        end

        # Summary display
        def summary(items, title: 'Summary')
          subsection_header(title, icon: :summary)
          items.each do |key, value|
            formatted_value = format_value(value)
            puts "  #{@pastel.white(key)}: #{formatted_value}"
          end
          puts
        end

        # Changes summary (create/update/destroy counts)
        def changes_summary(added: 0, changed: 0, destroyed: 0)
          subsection_header('Changes', icon: :diff)
          puts "  #{@pastel.green(ICONS[:create])} Added: #{added}"
          puts "  #{@pastel.yellow(ICONS[:update])} Changed: #{changed}"
          puts "  #{@pastel.red(ICONS[:delete])} Destroyed: #{destroyed}"
          puts
        end

        # Progress indicator
        def progress_message(message, status: :pending)
          icon = ICONS[status]
          color = COLORS[status] || :white
          puts @pastel.decorate("#{icon} #{message}", color)
        end

        # Code block with syntax highlighting
        def code_block(code, language: nil, line_numbers: false)
          puts
          if line_numbers
            code.lines.each_with_index do |line, idx|
              line_num = (idx + 1).to_s.rjust(4)
              puts "#{@pastel.bright_black(line_num)} #{line.chomp}"
            end
          else
            puts code
          end
          puts
        end

        # JSON output with syntax highlighting
        def json_output(data, indent: 2)
          formatted = JSON.pretty_generate(data, indent: ' ' * indent)

          highlighted = formatted
            .gsub(/"([^"]+)":/, @pastel.blue("\"\\1\":"))
            .gsub(/:\s*"([^"]+)"/, ": #{@pastel.green("\"\\1\"")}")
            .gsub(/:\s*(\d+)/, ": #{@pastel.cyan("\\1")}")
            .gsub(/:\s*(true|false)/, ": #{@pastel.yellow("\\1")}")
            .gsub(/([{}\[\],])/, @pastel.bright_black("\\1"))

          puts highlighted
          puts
        end

        # Diff output
        def diff_line(type, content)
          case type
          when :add
            puts @pastel.green("+ #{content}")
          when :remove
            puts @pastel.red("- #{content}")
          when :context
            puts @pastel.bright_black("  #{content}")
          when :header
            puts @pastel.cyan("@@ #{content} @@")
          end
        end

        # Separator line
        def separator(char: '─', width: 60, color: :bright_black)
          puts @pastel.decorate(char * width, color)
        end

        # Empty line
        def blank_line(count: 1)
          count.times { puts }
        end

        # Nested content with indentation
        def with_indent(levels: 1)
          @indent_level ||= 0
          @indent_level += levels
          yield
          @indent_level -= levels
        end

        # Get current indent string
        def indent
          ' ' * ((@indent_level || 0) * 2)
        end

        private

        # Format various value types for display
        def format_value(value)
          case value
          when String
            truncate_string(value)
          when Array
            if value.empty?
              @pastel.bright_black('[]')
            elsif value.length > 3
              formatted = value.first(3).join(', ')
              @pastel.bright_black("[#{formatted}, ... +#{value.length - 3} more]")
            else
              @pastel.bright_black("[#{value.join(', ')}]")
            end
          when Hash
            @pastel.bright_black("{#{value.size} items}")
          when Numeric
            @pastel.cyan(value.to_s)
          when TrueClass, FalseClass
            @pastel.yellow(value.to_s)
          when NilClass
            @pastel.bright_black('null')
          else
            @pastel.bright_black(value.to_s)
          end
        end

        def truncate_string(str, max_length: 60)
          if str.length > max_length
            @pastel.bright_black("#{str[0...max_length-3]}...")
          else
            @pastel.bright_black(str)
          end
        end
      end
    end
  end
end
