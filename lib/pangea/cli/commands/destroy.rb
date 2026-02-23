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
require 'pangea/cli/ui/command_display'

module Pangea
  module CLI
    module Commands
      # Destroy command - destroy infrastructure
      class Destroy < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        include UI::CommandDisplay

        def run(file_path, namespace:, template: nil, auto_approve: true)
          @workspace_manager = Execution::WorkspaceManager.new
          @auto_approve = auto_approve
          @namespace = namespace
          @start_time = Time.now

          display_command_header('Destroy Infrastructure', icon: :destroying, description: '⚠️  This will permanently delete all resources')

          # Load namespace configuration
          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          display_namespace_info(namespace_entity)

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

          display_execution_time(@start_time, operation: 'Total destroy')
        end

        private

        def destroy_template(template_name, namespace_entity)
          formatter.section_header("Destroying Template: #{template_name}", icon: :template)

          workspace = @workspace_manager.workspace_for(
            namespace: @namespace,
            project: template_name
          )

          unless Dir.exist?(workspace)
            formatter.status(:error, 'Workspace not found')
            formatter.kv_pair('Path', workspace, indent: 2)
            formatter.blank_line
            formatter.status(:info, "Run 'pangea apply' first to create resources")
            return
          end

          display_workspace_info(workspace)

          # Initialize executor
          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          # Check current state
          state_result = with_spinner("Checking current state...") do
            executor.state_list
          end

          if state_result[:success]
            if state_result[:resources].empty?
              formatter.status(:info, 'No resources found in state')
              formatter.kv_pair('Status', 'Nothing to destroy', indent: 2)
              formatter.blank_line
              return
            else
              display_resources_to_destroy(state_result[:resources], template_name)
            end
          else
            display_operation_failure('State check', state_result[:error])
            return
          end

          # Confirm destruction
          unless @auto_approve
            display_destroy_confirmation(template_name, state_result[:resources].count)
          end

          # Run destroy
          destroy_result = with_spinner("Destroying resources...") do
            executor.destroy(auto_approve: true)
          end

          if destroy_result[:success]
            display_destroy_success(template_name, workspace, state_result[:resources].count)

            # Clean workspace
            @workspace_manager.clean(workspace)
            formatter.status(:success, 'Workspace cleaned')
            formatter.kv_pair('Path', workspace, indent: 2)
            formatter.blank_line
          else
            display_operation_failure('Destroy', destroy_result[:error], details: destroy_result[:output])
          end
        end

        def display_resources_to_destroy(resources, template_name)
          formatter.subsection_header('Resources to Destroy', icon: :warning)
          formatter.blank_line

          formatter.status(:warning, "The following #{resources.count} resource(s) will be permanently deleted:")
          formatter.blank_line

          # Group by type
          grouped = resources.group_by { |r| r.split('.').first }

          grouped.sort.each do |type, type_resources|
            formatter.list_items(
              ["#{Boreal.paint(type, :delete)}: #{type_resources.count} instance(s)"],
              icon: '−',
              color: :delete,
              indent: 2
            )

            type_resources.first(3).each do |resource|
              formatter.list_items(
                [Boreal.paint(resource, :muted)],
                icon: '•',
                color: :delete,
                indent: 4
              )
            end

            if type_resources.count > 3
              formatter.list_items(
                [Boreal.paint("... and #{type_resources.count - 3} more", :muted)],
                icon: '•',
                color: :delete,
                indent: 4
              )
            end
          end

          formatter.blank_line
          formatter.kv_pair('Total resources', Boreal.paint(resources.count.to_s, :delete))
          formatter.blank_line
        end

        def display_destroy_confirmation(template_name, resource_count)
          formatter.blank_line
          formatter.warning_box(
            'DESTRUCTION WARNING',
            [
              "This will PERMANENTLY DELETE #{resource_count} resource(s) from template '#{template_name}'",
              'This action CANNOT be undone',
              'All data will be LOST'
            ],
            width: 70
          )
          formatter.blank_line
          formatter.status(:warning, 'Press Ctrl+C within 10 seconds to cancel...')
          sleep 10
          formatter.status(:info, 'Proceeding with destroy...')
          formatter.blank_line
        end

        def display_destroy_success(template_name, workspace, resource_count)
          display_operation_success('Destroy', details: {
            'Template' => template_name,
            'Resources destroyed' => resource_count.to_s,
            'Namespace' => @namespace
          })
        end
      end
    end
  end
end
