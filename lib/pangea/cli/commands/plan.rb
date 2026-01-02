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
require 'pangea/cli/ui/diff'
require 'pangea/cli/ui/progress'
require 'pangea/cli/ui/visualizer'

require_relative 'plan/json_analysis'
require_relative 'plan/resource_display'
require_relative 'plan/plan_output'
require_relative 'plan/json_formatting'

module Pangea
  module CLI
    module Commands
      # Plan command - show what changes would be made
      class Plan < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        include JsonAnalysis
        include ResourceDisplay
        include PlanOutput
        include JsonFormatting

        def run(file_path, namespace:, template: nil, show_compiled: false)
          @workspace_manager = Execution::WorkspaceManager.new
          @diff = UI::Diff.new
          @visualizer = UI::Visualizer.new
          @progress = UI::Progress.new
          @namespace = namespace
          @file_path = file_path
          @show_compiled = show_compiled

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          process_templates(
            file_path: file_path,
            namespace: namespace,
            template_name: template
          ) do |template_name, terraform_json|
            plan_template(template_name, terraform_json, namespace_entity)
          end
        end

        def plan_template(template_name, terraform_json, _namespace_entity)
          if @show_compiled
            display_compiled_json(template_name, terraform_json)
            return
          end

          resource_analysis = analyze_terraform_json(terraform_json)
          display_resource_analysis(template_name, resource_analysis)

          workspace = setup_workspace(
            template_name: template_name,
            terraform_json: terraform_json,
            namespace: @namespace,
            source_file: @file_path
          )

          return unless ensure_initialized(workspace)

          execute_plan(template_name, workspace, resource_analysis)
        end

        private

        def execute_plan(template_name, workspace, resource_analysis)
          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          plan_file = File.join(workspace, 'plan.tfplan')

          plan_result = with_spinner('Planning changes...') do
            executor.plan(out_file: plan_file)
          end

          handle_plan_result(template_name, workspace, plan_result, resource_analysis, executor)
        end

        def handle_plan_result(template_name, workspace, plan_result, resource_analysis, executor)
          if plan_result[:success]
            if plan_result[:changes]
              display_successful_plan(template_name, workspace, plan_result, resource_analysis)
            else
              display_no_changes(template_name, executor, resource_analysis)
            end
          else
            display_plan_failure(template_name, plan_result)
          end
        end

        def display_successful_plan(template_name, workspace, plan_result, resource_analysis)
          ui.success "Plan generated for template '#{template_name}'"
          ui.info "Plan saved to: #{File.join(workspace, 'plan.tfplan')}"

          display_enhanced_plan_output(plan_result, resource_analysis)

          ui.info "\nWorkspace: #{workspace}"
          ui.info "\nTo apply these changes, run:"
          template_flag = @template ? " --template #{@template}" : ''
          ui.info "  pangea apply #{@file_path} --namespace #{@namespace}#{template_flag}"
        end

        def display_no_changes(template_name, executor, resource_analysis)
          ui.info "No changes required for template '#{template_name}'. Infrastructure is up-to-date."
          display_current_state(executor, resource_analysis)
        end

        def display_plan_failure(template_name, plan_result)
          ui.error "Planning failed for template '#{template_name}':"
          ui.error plan_result[:error] if plan_result[:error]
          ui.error plan_result[:output] if plan_result[:output] && !plan_result[:output].empty?
        end
      end
    end
  end
end
