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
require 'pangea/cli/services/template_service'
require 'pangea/cli/services/workspace_service'
require 'pangea/cli/presenters/base_presenter'
require 'pangea/cli/presenters/destroy_presenter'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'

module Pangea
  module CLI
    module Commands
      # Destroy command - destroy infrastructure
      class Destroy < BaseCommand
        def run(file_path, namespace:, template: nil, auto_approve: true)
          @presenter  = Presenters::DestroyPresenter.new(ui: ui)
          templates   = Services::TemplateService.new(ui: ui)
          @workspaces = Services::WorkspaceService.new(
            workspace_manager: Execution::WorkspaceManager.new, ui: ui
          )
          @namespace    = namespace
          @auto_approve = auto_approve
          start_time    = Time.now

          @presenter.command_header(
            'Destroy Infrastructure', icon: :destroying,
            description: 'This will permanently delete all resources'
          )

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          @presenter.namespace_info(namespace_entity)

          if template
            destroy_template(template)
          else
            templates.process_all(
              file_path: file_path, namespace: namespace, template_name: nil
            ) do |name, _json|
              destroy_template(name)
            end
          end

          @presenter.execution_time(start_time, operation: 'Total destroy')
        end

        private

        def destroy_template(template_name)
          @presenter.formatter.section_header("Destroying Template: #{template_name}", icon: :template)

          workspace = @workspaces.workspace_for(namespace: @namespace, template_name: template_name)

          unless @workspaces.workspace_exists?(workspace)
            @presenter.workspace_not_found(workspace)
            return
          end

          @presenter.workspace_info(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          state_result = with_spinner("Checking current state...") { executor.state_list }

          if state_result[:success]
            if state_result[:resources].empty?
              @presenter.no_resources_in_state
              return
            else
              @presenter.resources_to_destroy(state_result[:resources], template_name)
            end
          else
            @presenter.operation_failure('State check', state_result[:error])
            return
          end

          unless @auto_approve
            @presenter.destroy_confirmation(template_name, state_result[:resources].count)
            sleep 10
            @presenter.progress('Proceeding with destroy...', status: :info)
          end

          destroy_result = with_spinner("Destroying resources...") { executor.destroy(auto_approve: true) }

          if destroy_result[:success]
            @presenter.destroy_success(template_name, namespace: @namespace, resource_count: state_result[:resources].count)
            @workspaces.clean(workspace)
            @presenter.workspace_cleaned(workspace)
          else
            @presenter.operation_failure('Destroy', destroy_result[:error], details: destroy_result[:output])
          end
        end
      end
    end
  end
end
