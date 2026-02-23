# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'diff/lcs'
require 'json'
require_relative 'diff/plan_parser'
require_relative 'diff/formatting'

module Pangea
  module CLI
    module UI
      # Beautiful diff output for terraform changes
      module Diff
        # Renderer for displaying formatted diffs
        class Renderer
          # Display terraform plan diff
          def terraform_plan(plan_output)
            return if plan_output.nil? || plan_output.empty?

            sections = PlanParser.parse_plan_output(plan_output)
            sections.each { |section| display_section(section) }
          end

          # Display JSON diff (for debugging)
          def json(old_json, new_json)
            old_pretty = JSON.pretty_generate(old_json)
            new_pretty = JSON.pretty_generate(new_json)
            diff_lines(old_pretty, new_pretty)
          end

          # Display resource diff
          def resource(resource_type, resource_name, changes)
            header = "#{resource_type}.#{resource_name}"
            puts "\n#{Boreal.bold(header)}"
            puts Boreal.paint('-' * header.length, :muted)
            changes.each { |attribute, change| display_attribute_change(attribute, change) }
          end

          private

          def display_section(section)
            case section[:type]
            when :resource
              display_resource_section(section)
            when :summary
              display_summary_section(section)
            end
          end

          def display_resource_section(section)
            icon, color = Formatting.action_style(section[:action])
            resource_line = "#{icon} #{section[:resource]}"
            puts "\n#{Boreal.paint(resource_line, color)}"
            section[:content].each { |line| display_diff_line(line) }
          end

          def display_summary_section(section)
            puts "\n#{Boreal.paint('-' * 60, :primary)}"
            section[:content].each { |line| format_summary_line(line) }
          end

          def format_summary_line(line)
            if line =~ /(\d+) to add, (\d+) to change, (\d+) to destroy/
              add, change, destroy = ::Regexp.last_match(1).to_i,
                                     ::Regexp.last_match(2).to_i,
                                     ::Regexp.last_match(3).to_i
              parts = build_summary_parts(add, change, destroy)
              puts "#{Boreal.bold('Plan: ')}#{parts.join(', ')}"
            else
              puts line
            end
          end

          def build_summary_parts(add, change, destroy)
            parts = []
            parts << Boreal.paint("#{add} to add", :added) if add.positive?
            parts << Boreal.paint("#{change} to change", :changed) if change.positive?
            parts << Boreal.paint("#{destroy} to destroy", :removed) if destroy.positive?
            parts
          end

          def display_diff_line(line)
            case line
            when /^      \+ (.+)$/
              puts Boreal.paint("  + #{::Regexp.last_match(1)}", :added)
            when /^      - (.+)$/
              puts Boreal.paint("  - #{::Regexp.last_match(1)}", :removed)
            when /^      ~ (.+)$/
              display_changed_line(::Regexp.last_match(1))
            when /^        (.+)$/
              puts Boreal.paint("    #{::Regexp.last_match(1)}", :muted)
            else
              puts line
            end
          end

          def display_changed_line(content)
            if content =~ /(.+) = (.+) -> (.+)$/
              attr = ::Regexp.last_match(1).strip
              old_val = ::Regexp.last_match(2).strip
              new_val = ::Regexp.last_match(3).strip
              formatted = Formatting.format_value_change(old_val, new_val)
              puts "  #{Boreal.paint('~', :changed)} #{attr} = #{formatted}"
            else
              puts Boreal.paint("  ~ #{content}", :changed)
            end
          end

          def display_attribute_change(attribute, change)
            return unless change.is_a?(Hash)

            if change[:old] && change[:new]
              display_modified_attribute(attribute, change)
            elsif change[:add]
              puts "  #{Boreal.paint('+', :added)} #{attribute}: #{Formatting.format_value(change[:add])}"
            elsif change[:remove]
              puts "  #{Boreal.paint('-', :removed)} #{attribute}: #{Formatting.format_value(change[:remove])}"
            end
          end

          def display_modified_attribute(attribute, change)
            old_val = Formatting.format_value(change[:old])
            new_val = Formatting.format_value(change[:new])
            formatted = Formatting.format_value_change(old_val, new_val)
            puts "  #{Boreal.paint('~', :changed)} #{attribute}: #{formatted}"
          end

          def diff_lines(old_text, new_text)
            diffs = ::Diff::LCS.diff(old_text.lines, new_text.lines)
            diffs.each do |diff|
              diff.each do |change|
                case change.action
                when '-'
                  puts Boreal.paint("- #{change.element.chomp}", :removed)
                when '+'
                  puts Boreal.paint("+ #{change.element.chomp}", :added)
                end
              end
            end
          end
        end
      end
    end
  end
end
