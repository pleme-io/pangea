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

module Pangea
  module CLI
    module Commands
      # Apply command - apply infrastructure changes
      class Apply < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        
        def run(file_path, namespace:, template: nil, auto_approve: true)
          @workspace_manager = Execution::WorkspaceManager.new
          @auto_approve = auto_approve
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
            apply_template(template_name, terraform_json, namespace_entity)
          end
        end
        
        private
        
        def apply_template(template_name, terraform_json, namespace_entity)
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
          
          # Run plan first to show changes if confirmation is required
          unless @auto_approve
            plan_result = with_spinner("Planning changes...") do
              executor.plan
            end
            
            if plan_result[:success]
              if plan_result[:changes]
                # Display changes
                if plan_result[:resource_changes]
                  display_resource_changes(plan_result[:resource_changes])
                end
                
                # Show changes summary
                ui.warn "\nChanges will be applied for template '#{template_name}'."
                ui.warn "Press Ctrl+C within 5 seconds to cancel..."
                sleep 5
                ui.info "Proceeding with apply..."
              else
                ui.info "No changes required for template '#{template_name}'. Infrastructure is up-to-date."
                return
              end
            else
              ui.error "Planning failed. Cannot proceed with apply."
              return
            end
          end
          
          # Apply changes
          apply_result = with_spinner("Applying changes...") do
            executor.apply(auto_approve: true)
          end
          
          if apply_result[:success]
            ui.success "Apply completed successfully for template '#{template_name}'!"
            
            # Show summary and outputs
            display_apply_summary(apply_result)
            display_outputs(executor)
          else
            ui.error "Apply failed for template '#{template_name}':"
            ui.error apply_result[:error] if apply_result[:error]
            ui.error apply_result[:output] if apply_result[:output] && !apply_result[:output].empty?
          end
        end
      end
    end
  end
end