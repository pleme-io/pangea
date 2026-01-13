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

module Pangea
  module CLI
    module Commands
      # Resource display methods for plan command
      module ResourceDisplay
          private

          def display_resource_analysis(template_name, analysis)
            return if analysis[:error]

            ui.info "\n Template Analysis: #{template_name}"
            ui.info '-' * 60

            display_analysis_summary(analysis[:summary])
            display_resource_breakdown(analysis[:summary])
            display_key_resources(analysis[:resources])
          end

          def display_analysis_summary(summary)
            ui.info ' Summary:'
            ui.say "  * #{ui.pastel.bold(summary[:total_resources])} resources defined"
            ui.say "  * #{ui.pastel.bold(summary[:providers].count)} provider(s): #{summary[:providers].join(', ')}"
            ui.say "  * #{ui.pastel.bold(summary[:variables_count])} variables"
            ui.say "  * #{ui.pastel.bold(summary[:outputs_count])} outputs"
            ui.say "  * Backend: #{summary[:has_backend] ? ui.pastel.green('configured') : ui.pastel.yellow('local')}"
            ui.say "  * Estimated cost: #{ui.pastel.cyan("$#{summary[:estimated_cost]}/month")}"
          end

          def display_resource_breakdown(summary)
            return unless summary[:resource_types].any?

            ui.info "\n  Resources by type:"
            summary[:resource_types].sort_by { |_, count| -count }.each do |type, count|
              ui.say "  * #{ui.pastel.cyan(type)}: #{count}"
            end
          end

          def display_key_resources(resources)
            return if resources.empty?

            ui.info "\n Resource Details:"

            resources.each do |resource|
              ui.say "  * #{ui.pastel.bold(resource[:full_name])}"
              display_resource_attrs(resource[:attributes])
            end
          end

          def display_resource_attrs(attributes)
            return unless attributes.any?

            attributes.each do |key, value|
              next if value.nil? || value.to_s.empty?

              formatted_value = format_attribute_value(value)
              ui.say "    #{key}: #{ui.pastel.bright_black(formatted_value)}"
            end
          end

          def format_attribute_value(value)
            case value
            when Array then value.join(', ')
            when Hash then value.to_json
            when String then value.length > 50 ? "#{value[0..47]}..." : value
            else value.to_s
            end
          end

          def display_resource_attributes(attributes, indent = '')
            return if attributes.empty?

            attributes.each do |key, value|
              next if value.nil? || value.to_s.empty?

              formatted_value = format_attribute_value(value)
              ui.say "#{indent}  #{key}: #{ui.pastel.bright_black(formatted_value)}"
            end
          end
        end
      end
    end
  end
