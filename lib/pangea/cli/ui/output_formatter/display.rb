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
            puts Boreal.paint(divider, :primary)
            puts Boreal.bold(full_title, :primary)
            puts Boreal.paint(divider, :primary)
            puts
          end

          def subsection_header(title, icon: nil)
            full_title = icon ? "#{ICONS[icon]}  #{title}:" : "#{title}:"
            puts Boreal.bold(full_title)
          end

          def status(type, message, details: nil)
            icon = ICONS[type]
            role = COLORS[type]
            puts Boreal.paint("#{icon} #{message}", role)
            details&.each { |key, value| puts "  #{Boreal.paint(key, :text)}: #{Boreal.paint(value, :muted)}" }
          end

          def kv_pair(key, value, indent: 2)
            puts "#{' ' * indent}#{Boreal.paint(key, :text)}: #{format_value(value)}"
          end

          def list_items(items, icon: '•', color: :text, indent: 2)
            items.each { |item| puts "#{' ' * indent}#{Boreal.paint(icon, color)} #{item}" }
          end

          def resource(type, name, attributes: {}, indent: 2)
            spaces = ' ' * indent
            puts "#{spaces}• #{Boreal.bold("#{type}.#{name}")}"
            attributes.each { |key, value| puts "#{spaces}  #{key}: #{Boreal.paint(format_value(value), :muted)}" }
          end

          def resource_change(action, type, name, attributes: {}, indent: 2)
            spaces = ' ' * indent
            puts "#{spaces}#{Boreal.paint(ICONS[action], COLORS[action])} #{Boreal.bold("#{type}.#{name}")}"
            attributes.each { |key, value| puts "#{spaces}  #{key}: #{Boreal.paint(format_value(value), :muted)}" }
          end

          def table(headers, rows, title: nil)
            puts
            puts Boreal.bold(title) if title
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
            puts Boreal.paint(divider, :success)
            puts Boreal.bold("#{ICONS[:success]} #{message}", :success)
            puts Boreal.paint(divider, :success)
            puts
          end

          def summary(items, title: 'Summary')
            subsection_header(title, icon: :summary)
            items.each { |key, value| puts "  #{Boreal.paint(key, :text)}: #{format_value(value)}" }
            puts
          end

          def changes_summary(added: 0, changed: 0, destroyed: 0)
            subsection_header('Changes', icon: :diff)
            puts "  #{Boreal.paint(ICONS[:create], :create)} Added: #{added}"
            puts "  #{Boreal.paint(ICONS[:update], :update)} Changed: #{changed}"
            puts "  #{Boreal.paint(ICONS[:delete], :delete)} Destroyed: #{destroyed}"
            puts
          end

          def progress_message(message, status: :pending)
            role = COLORS[status] || :text
            puts Boreal.paint("#{ICONS[status]} #{message}", role)
          end

          def code_block(code, language: nil, line_numbers: false)
            puts
            if line_numbers
              code.lines.each_with_index { |line, idx| puts "#{Boreal.paint((idx + 1).to_s.rjust(4), :muted)} #{line.chomp}" }
            else
              puts code
            end
            puts
          end

          def json_output(data, indent: 2)
            formatted = JSON.pretty_generate(data, indent: ' ' * indent)
            highlighted = formatted
              .gsub(/"([^"]+)":/, Boreal.paint("\"\\1\":", :info))
              .gsub(/:\s*"([^"]+)"/, ": #{Boreal.paint("\"\\1\"", :success)}")
              .gsub(/:\s*(\d+)/, ": #{Boreal.paint("\\1", :primary)}")
              .gsub(/:\s*(true|false)/, ": #{Boreal.paint("\\1", :update)}")
              .gsub(/([{}\[\],])/, Boreal.paint("\\1", :muted))
            puts highlighted
            puts
          end

          def diff_line(type, content)
            case type
            when :add then puts Boreal.paint("+ #{content}", :added)
            when :remove then puts Boreal.paint("- #{content}", :removed)
            when :context then puts Boreal.paint("  #{content}", :muted)
            when :header then puts Boreal.paint("@@ #{content} @@", :primary)
            end
          end

          def separator(char: '─', width: 60, color: :muted)
            puts Boreal.paint(char * width, color)
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
