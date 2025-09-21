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

module Pangea
  module CLI
    module Commands
      # Plan command - show what changes would be made
      class Plan < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        
        def run(file_path, namespace:, template: nil)
          @workspace_manager = Execution::WorkspaceManager.new
          @diff = UI::Diff.new
          @visualizer = UI::Visualizer.new
          @progress = UI::Progress.new
          @namespace = namespace
          @file_path = file_path
          
          # Load namespace configuration
          namespace_entity = load_namespace(namespace)
          return unless namespace_entity
          
          # Process templates using shared logic
          process_templates(
            file_path: file_path,
            namespace: namespace,
            template_name: template
          ) do |template_name, terraform_json|
            plan_template(template_name, terraform_json, namespace_entity)
          end
        end
        
        def plan_template(template_name, terraform_json, namespace_entity)
          # Set up workspace
          workspace = setup_workspace(
            template_name: template_name,
            terraform_json: terraform_json,
            namespace: @namespace,
            source_file: @file_path
          )
          
          # Initialize if needed
          return unless ensure_initialized(workspace)
          
          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          
          # Run plan
          plan_file = File.join(workspace, 'plan.tfplan')
          plan_result = with_spinner("Planning changes...") do
            executor.plan(out_file: plan_file)
          end
          
          if plan_result[:success]
            if plan_result[:changes]
              ui.success "Plan generated for template '#{template_name}'"
              ui.info "Plan saved to: #{plan_file}"
              
              # Display beautiful diff
              @diff.terraform_plan(plan_result[:output])
              
              # Show impact analysis
              if plan_result[:resource_changes]
                @visualizer.plan_impact({
                  create: plan_result[:resource_changes][:create] || [],
                  update: plan_result[:resource_changes][:update] || [],
                  destroy: plan_result[:resource_changes][:delete] || [],
                  details: {
                    create: plan_result[:resource_changes][:create]&.map { |r| { type: r.split('.').first, name: r.split('.').last } },
                    update: plan_result[:resource_changes][:update]&.map { |r| { type: r.split('.').first, name: r.split('.').last } },
                    destroy: plan_result[:resource_changes][:delete]&.map { |r| { type: r.split('.').first, name: r.split('.').last } }
                  }
                })
              end
              
              ui.info "\nWorkspace: #{workspace}"
              ui.info "\nTo apply these changes, run:"
              template_flag = @template ? " --template #{@template}" : ""
              ui.info "  pangea apply #{@file_path} --namespace #{@namespace}#{template_flag}"
            else
              ui.info "No changes required for template '#{template_name}'. Infrastructure is up-to-date."
            end
          else
            ui.error "Planning failed for template '#{template_name}':"
            ui.error plan_result[:error] if plan_result[:error]
            ui.error plan_result[:output] if plan_result[:output] && !plan_result[:output].empty?
          end
        end
        
        private
      end
    end
  end
end