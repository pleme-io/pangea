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
      class Plan
        # Plan output display methods
        module PlanOutput
          private

          def display_enhanced_plan_output(plan_result, resource_analysis)
            @diff.terraform_plan(plan_result[:output])

            display_detailed_resource_changes(plan_result[:resource_changes], resource_analysis) if plan_result[:resource_changes]

            return unless plan_result[:resource_changes]

            @visualizer.plan_impact({
                                      create: plan_result[:resource_changes][:create] || [],
                                      update: plan_result[:resource_changes][:update] || [],
                                      destroy: plan_result[:resource_changes][:delete] || [],
                                      details: build_enhanced_change_details(plan_result[:resource_changes], resource_analysis)
                                    })
          end

          def display_detailed_resource_changes(changes, resource_analysis)
            ui.info "\n Detailed Resource Changes:"
            ui.info '-' * 60

            %i[create update delete replace].each do |action|
              display_action_changes(action, changes[action], resource_analysis)
            end
          end

          def display_action_changes(action, resources, resource_analysis)
            return unless resources&.any?

            color, icon = action_style(action)

            ui.info "\n#{ui.pastel.decorate("#{icon} #{action.to_s.upcase}:", color)}"

            resources.each do |resource_ref|
              resource_info = find_resource_info(resource_ref, resource_analysis)
              if resource_info
                ui.say "  * #{ui.pastel.bold(resource_ref)}"
                display_resource_change_details(resource_info, action)
              else
                ui.say "  * #{resource_ref}"
              end
            end
          end

          def action_style(action)
            case action
            when :create then [:green, '+']
            when :update then [:yellow, '~']
            when :delete then [:red, '-']
            when :replace then [:magenta, '+/-']
            end
          end

          def find_resource_info(resource_ref, resource_analysis)
            return nil unless resource_analysis[:resources]

            resource_analysis[:resources].find { |r| r[:full_name] == resource_ref }
          end

          def display_resource_change_details(resource_info, action)
            case action
            when :create
              ui.say "    -> Creating new #{resource_info[:type]}"
              display_resource_attributes(resource_info[:attributes], '    ')
            when :delete
              ui.say "    -> #{ui.pastel.red('Warning: Will destroy existing resource')}"
              display_resource_attributes(resource_info[:attributes], '    ')
            when :update
              ui.say "    -> Modifying existing #{resource_info[:type]}"
            when :replace
              ui.say "    -> #{ui.pastel.magenta('Warning: Will replace (destroy + create)')}"
              display_resource_attributes(resource_info[:attributes], '    ')
            end
          end

          def build_enhanced_change_details(changes, resource_analysis)
            details = {}

            %i[create update destroy].each do |action|
              next unless changes[action]

              details[action] = changes[action].map do |resource_ref|
                resource_info = find_resource_info(resource_ref, resource_analysis)
                if resource_info
                  { type: resource_info[:type], name: resource_info[:name], attributes: resource_info[:attributes] }
                else
                  type, name = resource_ref.split('.', 2)
                  { type: type, name: name }
                end
              end
            end

            details
          end

          def display_current_state(executor, resource_analysis)
            ui.info "\n Current Infrastructure State:"
            ui.info '-' * 60

            state_result = executor.state_list

            if state_result[:success] && state_result[:resources]
              display_managed_resources(state_result[:resources])
            else
              ui.info 'No existing state found - this will be a fresh deployment'
            end

            display_template_resources(resource_analysis[:resources])
          end

          def display_managed_resources(resources)
            ui.info "#{resources.count} resources currently managed"

            grouped = resources.group_by { |r| r.split('.').first }
            grouped.each do |type, type_resources|
              ui.say "  * #{ui.pastel.cyan(type)}: #{type_resources.count} instance(s)"
            end
          end

          def display_template_resources(resources)
            return unless resources.any?

            ui.info "\n Resources defined in template:"
            resources.each do |resource|
              ui.say "  * #{ui.pastel.bright_black(resource[:full_name])}"
            end
          end
        end
      end
    end
  end
end
