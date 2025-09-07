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
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'

module Pangea
  module CLI
    module Commands
      # Destroy command - destroy infrastructure
      class Destroy < BaseCommand
        def run(file_path, namespace:, template: nil, auto_approve: true)
          @workspace_manager = Execution::WorkspaceManager.new
          @file_path = file_path
          @namespace = namespace
          @template = template
          @auto_approve = auto_approve
          
          # Load namespace configuration
          namespace_entity = load_namespace(@namespace)
          return unless namespace_entity
          
          # Get template name - need to handle multiple templates properly
          template_name = @template
          
          if template_name.nil?
            # Try to extract from file or require explicit template selection
            template_name = extract_project_from_file(@file_path)
            
            if template_name.nil?
              ui.error "Template name could not be determined from file '#{@file_path}'."
              ui.error "Use --template to specify which template to destroy."
              return
            end
          end
          
          workspace = @workspace_manager.workspace_for(
            namespace: @namespace,
            project: template_name
          )
          
          unless Dir.exist?(workspace)
            ui.error "Workspace not found: #{workspace}"
            ui.info "Have you run 'pangea apply' first?"
            return
          end
          
          # Load workspace metadata
          metadata = @workspace_manager.workspace_metadata(workspace)
          
          if metadata.any?
            ui.info "Workspace information:"
            ui.say "  Namespace: #{metadata[:namespace]}" if metadata[:namespace]
            ui.say "  Template: #{metadata[:template]}" if metadata[:template]
            ui.say "  Source: #{metadata[:source_file]}" if metadata[:source_file]
            ui.say ""
          end
          
          # Initialize executor
          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          
          # Check current state
          state_result = with_spinner("Checking current state...") do
            executor.state_list
          end
          
          if state_result[:success]
            if state_result[:resources].empty?
              ui.info "No resources found in state. Nothing to destroy."
              return
            else
              ui.warn "The following resources will be destroyed:"
              state_result[:resources].each { |r| ui.say "  - #{r}", color: :red }
              ui.say "\nTotal: #{state_result[:resources].count} resource(s)", color: :bright_cyan
            end
          else
            ui.error "Failed to read state. Cannot proceed with destroy."
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
          destroy_result = with_spinner("Destroying resources...") do
            executor.destroy(auto_approve: true)
          end
          
          if destroy_result[:success]
            ui.success "All resources have been destroyed for template '#{template_name}'!"
            
            # Clean terraform files
            @workspace_manager.clean(workspace)
            ui.info "Workspace cleaned: #{workspace}"
          else
            ui.error "Destroy failed for template '#{template_name}':"
            ui.error destroy_result[:error] if destroy_result[:error]
            ui.error destroy_result[:output] if destroy_result[:output] && !destroy_result[:output].empty?
          end
        end
        
        private
        
        def extract_project_from_file(file_path)
          # Try to extract project name from file path
          basename = File.basename(file_path, '.*')
          basename == 'main' ? nil : basename
        end
      end
    end
  end
end