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

require 'json'
require 'pangea/execution/terraform_executor'

module Pangea
  module CLI
    module Commands
      # Shared workspace operations for commands
      module WorkspaceOperations
        # Set up workspace and write terraform files
        def setup_workspace(template_name:, terraform_json:, namespace:, source_file:)
          workspace = @workspace_manager.workspace_for(
            namespace: namespace,
            project: template_name
          )
          
          # Write terraform files
          @workspace_manager.write_terraform_json(
            workspace: workspace,
            content: JSON.parse(terraform_json)
          )
          
          # Save metadata
          @workspace_manager.save_metadata(
            workspace: workspace,
            metadata: {
              namespace: namespace,
              template: template_name,
              source_file: source_file,
              compilation_time: Time.now.iso8601
            }
          )
          
          workspace
        end
        
        # Initialize terraform if needed
        def ensure_initialized(workspace)
          return true if @workspace_manager.initialized?(workspace)
          
          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          
          init_result = with_spinner("Initializing Terraform...") do
            executor.init
          end
          
          if init_result[:success]
            true
          else
            ui.error "Initialization failed: #{init_result[:error] || 'Unknown error'}"
            if init_result[:output] && !init_result[:output].empty?
              ui.error "Details:"
              init_result[:output].lines.last(10).each do |line|
                ui.error "  #{line.chomp}"
              end
            end
            false
          end
        end
        
        # Display workspace metadata
        def display_workspace_metadata(workspace, template_name)
          metadata = @workspace_manager.workspace_metadata(workspace)
          
          if metadata.any?
            ui.info "Workspace information for template '#{template_name}':"
            ui.say "  Namespace: #{metadata[:namespace]}" if metadata[:namespace]
            ui.say "  Template: #{metadata[:template]}" if metadata[:template]
            ui.say "  Source: #{metadata[:source_file]}" if metadata[:source_file]
            ui.say ""
          end
        end
        
        # Format output values for display
        def format_output_value(value)
          case value
          when String
            value
          when Array
            "[#{value.join(', ')}]"
          when Hash
            value.to_json
          else
            value.to_s
          end
        end
        
        # Display resource changes in a consistent format
        def display_resource_changes(changes)
          ui.info "\nResource changes:"
          
          if changes[:create]&.any?
            ui.info "\n  + Resources to create:", color: :green
            changes[:create].each { |r| ui.say "    #{r}" }
          end
          
          if changes[:update]&.any?
            ui.info "\n  ~ Resources to update:", color: :yellow
            changes[:update].each { |r| ui.say "    #{r}" }
          end
          
          if changes[:replace]&.any?
            ui.info "\n  +/- Resources to replace:", color: :magenta
            changes[:replace].each { |r| ui.say "    #{r}" }
          end
          
          if changes[:delete]&.any?
            ui.info "\n  - Resources to destroy:", color: :red
            changes[:delete].each { |r| ui.say "    #{r}" }
          end
          
          total = changes.values.compact.map(&:count).sum
          ui.say "\nTotal: #{total} resource(s) will be affected", color: :bright_cyan
        end
        
        # Display apply summary
        def display_apply_summary(result)
          if result[:added] || result[:changed] || result[:destroyed]
            ui.info "\nSummary:"
            ui.say "  Added: #{result[:added] || 0}", color: :green
            ui.say "  Changed: #{result[:changed] || 0}", color: :yellow
            ui.say "  Destroyed: #{result[:destroyed] || 0}", color: :red
          end
        end
        
        # Display terraform outputs
        def display_outputs(executor)
          output_result = executor.output
          if output_result[:success] && output_result[:data] && !output_result[:data].empty?
            ui.info "\nOutputs:"
            output_result[:data].each do |name, data|
              value = data['value']
              ui.say "  #{name}: #{format_output_value(value)}", color: :bright_cyan
            end
          end
        end
      end
    end
  end
end