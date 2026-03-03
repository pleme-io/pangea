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
      # Apply command - apply infrastructure changes
      class Apply < BaseCommand
        def run(file_path, namespace:, template: nil, auto_approve: true, show_compiled: false)
          @presenter  = Presenters::ApplyPresenter.new(ui: ui)
          templates   = Services::TemplateService.new(ui: ui)
          workspaces  = Services::WorkspaceService.new(
            workspace_manager: Execution::WorkspaceManager.new, ui: ui
          )
          @namespace  = namespace
          @file_path  = file_path
          start_time  = Time.now

          @presenter.command_header('Apply Infrastructure Changes', icon: :applying)

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          @presenter.namespace_info(namespace_entity)

          templates.process_all(
            file_path: file_path, namespace: namespace, template_name: template
          ) do |name, json|
            apply_template(name, json, workspaces, auto_approve: auto_approve, show_compiled: show_compiled)
          end

          @presenter.execution_time(start_time, operation: 'Total apply')
        end

        private

        def apply_template(template_name, terraform_json, workspaces, auto_approve:, show_compiled:)
          parsed = @presenter.compiled_template(template_name, terraform_json, show_full: show_compiled)
          return unless parsed

          workspace = workspaces.setup(
            template_name: template_name, terraform_json: terraform_json,
            namespace: @namespace, source_file: @file_path
          )
          @presenter.workspace_info(workspace)

          return unless workspaces.ensure_initialized(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          plan_result = with_spinner("Planning changes...") { executor.plan }
          unless plan_result[:success]
            @presenter.operation_failure('Planning', plan_result[:error])
            return
          end

          resource_analysis = { resources: extract_resources(JSON.parse(terraform_json)) }
          @presenter.plan(plan_result, resource_analysis: resource_analysis)
          return unless plan_result[:changes]

          unless auto_approve
            @presenter.confirmation_prompt(action: 'apply', timeout: 5)
            sleep 5
            @presenter.progress('Proceeding with apply...', status: :info)
          end

          apply_result = with_spinner("Applying changes...") { executor.apply(auto_approve: true) }

          if apply_result[:success]
            @presenter.apply_success(template_name, apply_result, resource_analysis, namespace: @namespace)
            @presenter.terraform_outputs(executor.output)
          else
            @presenter.operation_failure('Apply', apply_result[:error], details: apply_result[:output])
          end
        end

        def extract_resources(parsed)
          return [] unless parsed['resource']

          resources = []
          parsed['resource'].each do |rtype, instances|
            next unless instances.is_a?(Hash)

            instances.each do |rname, rcfg|
              next unless rcfg.is_a?(Hash)

              resources << { type: rtype, name: rname, full_name: "#{rtype}.#{rname}" }
            end
          end
          resources
        end
      end
    end
  end
end
