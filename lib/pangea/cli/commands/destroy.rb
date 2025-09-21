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
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'

module Pangea
  module CLI
    module Commands
      # Destroy command - destroy infrastructure
      class Destroy < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        
        def run(file_path, namespace:, template: nil, auto_approve: true)
          @workspace_manager = Execution::WorkspaceManager.new
          @auto_approve = auto_approve
          
          # Load namespace configuration
          namespace_entity = load_namespace(@namespace)
          return unless namespace_entity
          
          if template
            # Specific template requested
            destroy_template(template, namespace_entity)
          else
            # Use template processor to handle multiple templates
            process_templates(
              file_path: file_path,
              namespace: namespace,
              template_name: nil
            ) do |template_name, _terraform_json|
              destroy_template(template_name, namespace_entity)
            end
          end
        end
        
        private
        
        def destroy_template(template_name, namespace_entity)
          workspace = @workspace_manager.workspace_for(
            namespace: @namespace,
            project: template_name
          )
          
          unless Dir.exist?(workspace)
            ui.error "Workspace not found for template '#{template_name}': #{workspace}"
            ui.info "Have you run 'pangea apply' first?"
            return
          end
          
          # Display workspace metadata
          display_workspace_metadata(workspace, template_name)
          
          # Initialize executor
          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          
          # Check current state
          state_result = with_spinner("Checking current state for template '#{template_name}'...") do
            executor.state_list
          end
          
          if state_result[:success]
            if state_result[:resources].empty?
              ui.info "No resources found in state for template '#{template_name}'. Nothing to destroy."
              return
            else
              ui.warn "The following resources will be destroyed for template '#{template_name}':"
              state_result[:resources].each { |r| ui.say "  - #{r}", color: :red }
              ui.say "\nTotal: #{state_result[:resources].count} resource(s)", color: :bright_cyan
            end
          else
            ui.error "Failed to read state for template '#{template_name}'. Cannot proceed with destroy."
            return
          end
          
          # Confirm destruction
          unless @auto_approve
            ui.error "\nWARNING: This will destroy all resources for template '#{template_name}'!"
            ui.warn "Press Ctrl+C within 10 seconds to cancel..."
            sleep 10
            ui.info "Proceeding with destroy..."
          end
          
          # Run destroy
          destroy_result = with_spinner("Destroying resources for template '#{template_name}'...") do
            executor.destroy(auto_approve: true)
          end
          
          if destroy_result[:success]
            ui.success "All resources have been destroyed for template '#{template_name}'!"
            
            # Clean terraform files
            @workspace_manager.clean(workspace)
            ui.info "Workspace cleaned for template '#{template_name}': #{workspace}"
          else
            ui.error "Destroy failed for template '#{template_name}':"
            ui.error destroy_result[:error] if destroy_result[:error]
            ui.error destroy_result[:output] if destroy_result[:output] && !destroy_result[:output].empty?
          end
        end
      end
    end
  end
end