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

require 'pangea/cli/ui/output_formatter'
require 'pangea/cli/ui/diff'
require 'pangea/cli/ui/visualizer'
require_relative 'plan_display/action_group_display'

module Pangea
  module CLI
    module UI
      # Plan display utilities for consistent plan visualization
      module PlanDisplay
        include ActionGroupDisplay
        def formatter
          @formatter ||= OutputFormatter.new
        end

        def diff_viewer
          @diff_viewer ||= Diff.new
        end

        def visualizer
          @visualizer ||= Visualizer.new
        end

        # Display complete plan with all details
        def display_plan(plan_result, resource_analysis: nil, show_diff: true)
          formatter.section_header('Execution Plan', icon: :plan)

          if plan_result[:changes]
            display_plan_with_changes(plan_result, resource_analysis, show_diff)
          else
            display_no_changes(resource_analysis)
          end
        end

        # Display plan with changes
        def display_plan_with_changes(plan_result, resource_analysis, show_diff)
          # Show terraform diff output
          if show_diff && plan_result[:output]
            diff_viewer.terraform_plan(plan_result[:output])
          end

          # Show detailed resource changes
          if plan_result[:resource_changes]
            display_resource_changes(plan_result[:resource_changes], resource_analysis)
          end

          # Show visual impact summary
          if plan_result[:resource_changes]
            display_impact_visualization(plan_result[:resource_changes])
          end
        end

        # Display when no changes are needed
        def display_no_changes(resource_analysis)
          formatter.status(:success, 'No changes required')
          formatter.kv_pair('Status', formatter.pastel.green('Infrastructure is up-to-date'))

          if resource_analysis && resource_analysis[:resources]
            count = resource_analysis[:resources].count
            formatter.kv_pair('Resources managed', formatter.pastel.cyan(count.to_s))
          end

          formatter.blank_line
        end

        # Display detailed resource changes
        def display_resource_changes(changes, resource_analysis)
          formatter.subsection_header('Resource Changes', icon: :diff)

          total_changes = 0
          [:create, :update, :delete, :replace].each do |action|
            next unless changes[action] && changes[action].any?

            display_action_group(action, changes[action], resource_analysis)
            total_changes += changes[action].count
          end

          formatter.blank_line
          formatter.kv_pair(
            'Total changes',
            formatter.pastel.bold("#{total_changes} resource(s) will be modified")
          )
          formatter.blank_line
        end

        # Display impact visualization
        def display_impact_visualization(changes)
          visualizer.plan_impact(
            create: changes[:create] || [],
            update: changes[:update] || [],
            destroy: changes[:delete] || []
          )
        end

        # Display confirmation prompt
        def display_confirmation_prompt(action: 'apply', timeout: 5)
          formatter.blank_line
          formatter.status(
            :warning,
            "Changes will be #{action}ed. Press Ctrl+C within #{timeout} seconds to cancel..."
          )
        end

        # Display plan file information
        def display_plan_file_info(plan_file, workspace)
          formatter.subsection_header('Plan File', icon: :info)
          formatter.kv_pair('Location', plan_file)
          formatter.kv_pair('Workspace', workspace)
          formatter.blank_line
        end

        # Display next steps
        def display_next_steps(command, namespace, template)
          formatter.subsection_header('Next Steps', icon: :info)

          formatter.list_items([
            "Review the plan above carefully",
            "To apply: #{formatter.pastel.cyan("pangea #{command} --namespace #{namespace}#{template ? " --template #{template}" : ""}")}",
            "To destroy: #{formatter.pastel.cyan("pangea destroy --namespace #{namespace}#{template ? " --template #{template}" : ""}")}"
          ], icon: '→')

          formatter.blank_line
        end

        private

        def find_resource_info(resource_ref, resource_analysis)
          return nil unless resource_analysis && resource_analysis[:resources]

          resource_analysis[:resources].find { |r| r[:full_name] == resource_ref }
        end

        def format_attribute_value(value)
          case value
          when String
            value.length > 50 ? "#{value[0..47]}..." : value
          when Array
            value.join(', ')
          when Hash
            value.to_json
          else
            value.to_s
          end
        end
      end
    end
  end
end
