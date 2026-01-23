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
          def initialize
            @pastel = Pastel.new
          end

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
            puts "\n#{@pastel.bold(header)}"
            puts @pastel.bright_black('-' * header.length)
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
            puts "\n#{@pastel.decorate(resource_line, color)}"
            section[:content].each { |line| display_diff_line(line) }
          end

          def display_summary_section(section)
            puts "\n#{@pastel.bright_cyan('-' * 60)}"
            section[:content].each { |line| format_summary_line(line) }
          end

          def format_summary_line(line)
            if line =~ /(\d+) to add, (\d+) to change, (\d+) to destroy/
              add, change, destroy = ::Regexp.last_match(1).to_i,
                                     ::Regexp.last_match(2).to_i,
                                     ::Regexp.last_match(3).to_i
              parts = build_summary_parts(add, change, destroy)
              puts "#{@pastel.bold('Plan: ')}#{parts.join(', ')}"
            else
              puts line
            end
          end

          def build_summary_parts(add, change, destroy)
            parts = []
            parts << @pastel.green("#{add} to add") if add.positive?
            parts << @pastel.yellow("#{change} to change") if change.positive?
            parts << @pastel.red("#{destroy} to destroy") if destroy.positive?
            parts
          end

          def display_diff_line(line)
            case line
            when /^      \+ (.+)$/
              puts @pastel.green("  + #{::Regexp.last_match(1)}")
            when /^      - (.+)$/
              puts @pastel.red("  - #{::Regexp.last_match(1)}")
            when /^      ~ (.+)$/
              display_changed_line(::Regexp.last_match(1))
            when /^        (.+)$/
              puts @pastel.bright_black("    #{::Regexp.last_match(1)}")
            else
              puts line
            end
          end

          def display_changed_line(content)
            if content =~ /(.+) = (.+) -> (.+)$/
              attr = ::Regexp.last_match(1).strip
              old_val = ::Regexp.last_match(2).strip
              new_val = ::Regexp.last_match(3).strip
              formatted = Formatting.format_value_change(old_val, new_val, @pastel)
              puts "  #{@pastel.yellow('~')} #{attr} = #{formatted}"
            else
              puts @pastel.yellow("  ~ #{content}")
            end
          end

          def display_attribute_change(attribute, change)
            return unless change.is_a?(Hash)

            if change[:old] && change[:new]
              display_modified_attribute(attribute, change)
            elsif change[:add]
              puts "  #{@pastel.green('+')} #{attribute}: #{Formatting.format_value(change[:add])}"
            elsif change[:remove]
              puts "  #{@pastel.red('-')} #{attribute}: #{Formatting.format_value(change[:remove])}"
            end
          end

          def display_modified_attribute(attribute, change)
            old_val = Formatting.format_value(change[:old])
            new_val = Formatting.format_value(change[:new])
            formatted = Formatting.format_value_change(old_val, new_val, @pastel)
            puts "  #{@pastel.yellow('~')} #{attribute}: #{formatted}"
          end

          def diff_lines(old_text, new_text)
            diffs = ::Diff::LCS.diff(old_text.lines, new_text.lines)
            diffs.each do |diff|
              diff.each do |change|
                case change.action
                when '-'
                  puts @pastel.red("- #{change.element.chomp}")
                when '+'
                  puts @pastel.green("+ #{change.element.chomp}")
                end
              end
            end
          end
        end
      end
    end
  end
end
