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


require 'pangea/cli/commands/base_command'
require 'pangea/cli/commands/template_processor'
require 'pangea/cli/commands/workspace_operations'
require 'pangea/compilation/validator'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'
require 'pangea/backends'
require 'pangea/cli/ui/template_display'
require 'pangea/cli/ui/plan_display'
require 'pangea/cli/ui/command_display'

module Pangea
  module CLI
    module Commands
      # Apply command - apply infrastructure changes
      class Apply < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        include UI::TemplateDisplay
        include UI::PlanDisplay
        include UI::CommandDisplay

        def run(file_path, namespace:, template: nil, auto_approve: true, show_compiled: false)
          @workspace_manager = Execution::WorkspaceManager.new
          @auto_approve = auto_approve
          @show_compiled = show_compiled
          @namespace = namespace
          @file_path = file_path
          @start_time = Time.now

          display_command_header('Apply Infrastructure Changes', icon: :applying)

          # Load namespace configuration
          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          display_namespace_info(namespace_entity)

          # Process templates using shared logic
          process_templates(
            file_path: file_path,
            namespace: namespace,
            template_name: template
          ) do |template_name, terraform_json|
            apply_template(template_name, terraform_json, namespace_entity)
          end

          display_execution_time(@start_time, operation: 'Total apply')
        end

        private

        def apply_template(template_name, terraform_json, namespace_entity)
          # Display the compiled template
          resource_analysis = display_compiled_template(template_name, terraform_json, show_full: @show_compiled)
          return unless resource_analysis

          # Set up workspace
          workspace = setup_workspace(
            template_name: template_name,
            terraform_json: terraform_json,
            namespace: @namespace,
            source_file: @file_path
          )

          display_workspace_info(workspace)

          # Initialize if needed
          return unless ensure_initialized(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          # Always run plan first to show what will be applied
          plan_result = with_spinner("Planning changes...") do
            executor.plan
          end

          unless plan_result[:success]
            display_operation_failure('Planning', plan_result[:error])
            return
          end

          # Build resource analysis from template
          resource_analysis = {
            resources: extract_resources(JSON.parse(terraform_json))
          }

          # Display the plan
          display_plan(plan_result, resource_analysis: resource_analysis)

          # Check if there are changes
          unless plan_result[:changes]
            return
          end

          # Prompt for confirmation if not auto-approved
          unless @auto_approve
            display_confirmation_prompt(action: 'apply', timeout: 5)
            sleep 5
            display_progress('Proceeding with apply...', status: :info)
          end

          # Apply changes
          apply_result = with_spinner("Applying changes...") do
            executor.apply(auto_approve: true)
          end

          if apply_result[:success]
            display_apply_success(template_name, apply_result, resource_analysis)
            display_terraform_outputs(executor.output)
          else
            display_operation_failure('Apply', apply_result[:error], details: apply_result[:output])
          end
        end

        def display_apply_success(template_name, apply_result, resource_analysis)
          display_operation_success('Apply', details: {
            'Template' => template_name,
            'Namespace' => @namespace,
            'Resources managed' => resource_analysis[:resources].count.to_s
          })

          display_changes_summary(
            added: apply_result[:added] || 0,
            changed: apply_result[:changed] || 0,
            destroyed: apply_result[:destroyed] || 0
          )
        end
      end
    end
  end
end
