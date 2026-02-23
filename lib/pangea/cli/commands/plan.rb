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
require 'pangea/cli/presenters/plan_presenter'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'

module Pangea
  module CLI
    module Commands
      # Plan command - show what changes would be made
      class Plan < BaseCommand
        def run(file_path, namespace:, template: nil, show_compiled: false)
          @presenter  = Presenters::PlanPresenter.new(ui: ui)
          templates   = Services::TemplateService.new(ui: ui)
          @workspaces = Services::WorkspaceService.new(
            workspace_manager: Execution::WorkspaceManager.new, ui: ui
          )
          @namespace  = namespace
          @file_path  = file_path
          @template   = template

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          templates.process_all(
            file_path: file_path, namespace: namespace, template_name: template
          ) do |name, json|
            plan_template(name, json, show_compiled: show_compiled)
          end
        end

        private

        def plan_template(template_name, terraform_json, show_compiled:)
          if show_compiled
            @presenter.compiled_json(template_name, terraform_json)
            return
          end

          analysis = @presenter.analyze_terraform_json(terraform_json)
          @presenter.resource_analysis(template_name, analysis)

          workspace = @workspaces.setup(
            template_name: template_name, terraform_json: terraform_json,
            namespace: @namespace, source_file: @file_path
          )

          return unless @workspaces.ensure_initialized(workspace)

          execute_plan(template_name, workspace, analysis)
        end

        def execute_plan(template_name, workspace, analysis)
          executor  = Execution::TerraformExecutor.new(working_dir: workspace)
          plan_file = File.join(workspace, 'plan.tfplan')

          plan_result = with_spinner('Planning changes...') { executor.plan(out_file: plan_file) }

          if plan_result[:success]
            if plan_result[:changes]
              @presenter.successful_plan(
                template_name, workspace, plan_result, analysis,
                file_path: @file_path, namespace: @namespace, template_flag: @template
              )
            else
              @presenter.no_changes(template_name, executor, analysis)
            end
          else
            @presenter.plan_failure(template_name, plan_result)
          end
        end
      end
    end
  end
end
