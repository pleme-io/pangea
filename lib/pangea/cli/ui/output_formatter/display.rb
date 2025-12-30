# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'json'

module Pangea
  module CLI
    module UI
      class OutputFormatter
        module Display
          def section_header(title, icon: nil, width: 60)
            full_title = icon ? "#{ICONS[icon]} #{title}" : title
            divider = '━' * width
            puts
            puts @pastel.cyan(divider)
            puts @pastel.bold(@pastel.cyan(full_title))
            puts @pastel.cyan(divider)
            puts
          end

          def subsection_header(title, icon: nil)
            full_title = icon ? "#{ICONS[icon]}  #{title}:" : "#{title}:"
            puts @pastel.bold(full_title)
          end

          def status(type, message, details: nil)
            icon = ICONS[type]
            color = COLORS[type]
            puts @pastel.decorate("#{icon} #{message}", color)
            details&.each { |key, value| puts "  #{@pastel.white(key)}: #{@pastel.bright_black(value)}" }
          end

          def kv_pair(key, value, indent: 2)
            puts "#{' ' * indent}#{@pastel.white(key)}: #{format_value(value)}"
          end

          def list_items(items, icon: '•', color: :white, indent: 2)
            items.each { |item| puts "#{' ' * indent}#{@pastel.decorate(icon, color)} #{item}" }
          end

          def resource(type, name, attributes: {}, indent: 2)
            spaces = ' ' * indent
            puts "#{spaces}• #{@pastel.decorate("#{type}.#{name}", :bold)}"
            attributes.each { |key, value| puts "#{spaces}  #{key}: #{@pastel.bright_black(format_value(value))}" }
          end

          def resource_change(action, type, name, attributes: {}, indent: 2)
            spaces = ' ' * indent
            puts "#{spaces}#{@pastel.decorate(ICONS[action], COLORS[action])} #{@pastel.bold("#{type}.#{name}")}"
            attributes.each { |key, value| puts "#{spaces}  #{key}: #{@pastel.bright_black(format_value(value))}" }
          end

          def table(headers, rows, title: nil)
            puts
            puts @pastel.bold(title) if title
            table = TTY::Table.new(headers, rows)
            puts table.render(:unicode, padding: [0, 1])
            puts
          end

          def info_box(title, content, width: 60)
            puts TTY::Box.frame(width: width, title: { top_left: title }, border: :light, padding: 1, style: { border: { fg: :cyan } }) { content }
          end

          def warning_box(title, warnings, width: 60)
            content = warnings.map { |w| "#{ICONS[:warning]} #{w}" }.join("\n")
            puts TTY::Box.frame(width: width, title: { top_left: "⚠️  #{title}" }, border: :thick, padding: 1, style: { border: { fg: :yellow } }) { content }
          end

          def error_box(title, errors, width: 60)
            content = errors.map { |e| "#{ICONS[:error]} #{e}" }.join("\n")
            puts TTY::Box.frame(width: width, title: { top_left: "❌ #{title}" }, border: :thick, padding: 1, style: { border: { fg: :red } }) { content }
          end

          def success_banner(message, width: 60)
            divider = '━' * width
            puts
            puts @pastel.green(divider)
            puts @pastel.bold(@pastel.green("#{ICONS[:success]} #{message}"))
            puts @pastel.green(divider)
            puts
          end

          def summary(items, title: 'Summary')
            subsection_header(title, icon: :summary)
            items.each { |key, value| puts "  #{@pastel.white(key)}: #{format_value(value)}" }
            puts
          end

          def changes_summary(added: 0, changed: 0, destroyed: 0)
            subsection_header('Changes', icon: :diff)
            puts "  #{@pastel.green(ICONS[:create])} Added: #{added}"
            puts "  #{@pastel.yellow(ICONS[:update])} Changed: #{changed}"
            puts "  #{@pastel.red(ICONS[:delete])} Destroyed: #{destroyed}"
            puts
          end

          def progress_message(message, status: :pending)
            puts @pastel.decorate("#{ICONS[status]} #{message}", COLORS[status] || :white)
          end

          def code_block(code, language: nil, line_numbers: false)
            puts
            if line_numbers
              code.lines.each_with_index { |line, idx| puts "#{@pastel.bright_black((idx + 1).to_s.rjust(4))} #{line.chomp}" }
            else
              puts code
            end
            puts
          end

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

          def diff_line(type, content)
            case type
            when :add then puts @pastel.green("+ #{content}")
            when :remove then puts @pastel.red("- #{content}")
            when :context then puts @pastel.bright_black("  #{content}")
            when :header then puts @pastel.cyan("@@ #{content} @@")
            end
          end

          def separator(char: '─', width: 60, color: :bright_black)
            puts @pastel.decorate(char * width, color)
          end

          def blank_line(count: 1)
            count.times { puts }
          end

          def with_indent(levels: 1)
            @indent_level ||= 0
            @indent_level += levels
            yield
            @indent_level -= levels
          end

          def indent
            ' ' * ((@indent_level || 0) * 2)
          end
        end
      end
    end
  end
end
