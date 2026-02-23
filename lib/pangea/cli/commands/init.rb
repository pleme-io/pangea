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
require 'pangea/cli/presenters/apply_presenter'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'

module Pangea
  module CLI
    module Commands
      # Init command - initialize Terraform workspace
      class Init < BaseCommand
        def run(file_path, namespace:, template: nil)
          @presenter  = Presenters::ApplyPresenter.new(ui: ui)
          templates   = Services::TemplateService.new(ui: ui)
          @workspaces = Services::WorkspaceService.new(
            workspace_manager: Execution::WorkspaceManager.new, ui: ui
          )
          @namespace = namespace
          @file_path = file_path
          start_time = Time.now

          @presenter.command_header('Initialize Terraform Workspace', icon: :initializing)

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          @presenter.namespace_info(namespace_entity)

          templates.process_all(
            file_path: file_path, namespace: namespace, template_name: template
          ) do |name, json|
            init_template(name, json, namespace_entity)
          end

          @presenter.execution_time(start_time, operation: 'Total initialization')
        end

        private

        def init_template(template_name, terraform_json, namespace_entity)
          @presenter.compiled_template(template_name, terraform_json, show_full: false)

          workspace = @workspaces.setup(
            template_name: template_name, terraform_json: terraform_json,
            namespace: @namespace, source_file: @file_path
          )

          @presenter.workspace_info(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          @presenter.formatter.section_header('Initializing Terraform', icon: :initializing)
          @presenter.formatter.progress_message('Running: tofu init', status: :pending)
          @presenter.formatter.blank_line

          result = executor.init(stream_output: true)

          @presenter.formatter.blank_line

          if result[:success]
            @presenter.operation_success('Initialization', details: {
              'Template' => template_name,
              'Workspace' => workspace,
              'Backend' => namespace_entity.state.type.to_s
            })
          else
            @presenter.operation_failure('Initialization', result[:error], details: result[:output])
            exit 1
          end
        end
      end
    end
  end
end
