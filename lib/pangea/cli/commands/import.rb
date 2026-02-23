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
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'
require_relative 'import/resource_analyzer'
require_relative 'import/import_command_generator'

module Pangea
  module CLI
    module Commands
      # Import command - import existing resources into terraform state
      class Import < BaseCommand
        def run(file_path, namespace:, template: nil, resource: nil, id: nil)
          @templates  = Services::TemplateService.new(ui: ui)
          @workspaces = Services::WorkspaceService.new(
            workspace_manager: Execution::WorkspaceManager.new, ui: ui
          )
          @namespace = namespace
          @file_path = file_path

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          if resource && id
            import_single_resource(resource, id, template)
          else
            @templates.process_all(
              file_path: file_path, namespace: namespace, template_name: template
            ) do |name, json|
              interactive_import(name, json)
            end
          end
        end

        private

        def import_single_resource(resource_address, resource_id, template_name)
          workspace = @workspaces.workspace_for(namespace: @namespace, template_name: template_name)

          unless @workspaces.workspace_exists?(workspace)
            ui.error "Workspace not initialized. Run 'pangea plan' first to initialize."
            return
          end

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          ui.info "Importing resource: #{resource_address}"
          ui.info "Resource ID: #{resource_id}"

          result = with_spinner("Importing #{resource_address}...") do
            executor.import_resource(resource_address, resource_id)
          end

          if result[:success]
            ui.success "Successfully imported #{resource_address}"
            verify_import(executor)
          else
            ui.error "Import failed: #{result[:error]}"
          end
        end

        def verify_import(executor)
          ui.info "\nRunning plan to verify import..."
          plan_result = executor.plan
          return unless plan_result[:success]

          if plan_result[:changes]
            ui.warn "Import successful but there are pending changes"
          else
            ui.success "Import verified - no changes required"
          end
        end

        def interactive_import(template_name, terraform_json)
          ui.info "Interactive import for template: #{template_name}"
          ui.info "\u2500" * 60

          resources = ImportResourceAnalyzer.analyze_resources(terraform_json)

          if resources.empty?
            ui.warn "No resources found in template"
            return
          end

          display_resources(resources)
          display_import_commands(resources)

          workspace = @workspaces.setup(
            template_name: template_name, terraform_json: terraform_json,
            namespace: @namespace, source_file: @file_path
          )

          @workspaces.ensure_initialized(workspace)

          ui.info "\nWorkspace ready at: #{workspace}"
          ui.info "\nTo import resources manually, run:"
          ui.say "  cd #{workspace}"
          ui.say "  tofu import RESOURCE_ADDRESS RESOURCE_ID"
          ui.info "\nOr use pangea import with --resource and --id flags:"
          ui.say "  pangea import #{@file_path} --namespace #{@namespace} " \
                 "--template #{template_name} --resource RESOURCE_ADDRESS --id RESOURCE_ID"
        end

        def display_resources(resources)
          ui.info "Resources defined in template:"
          resources.each_with_index do |resource, idx|
            ui.say "  #{idx + 1}. #{Boreal.paint(resource[:address], :primary)} (#{resource[:type]})"
            resource[:attributes].each do |key, value|
              ui.say "     #{key}: #{value}" if value
            end
          end
        end

        def display_import_commands(resources)
          ui.info "\nTo import existing AWS resources, you'll need their IDs:"
          ui.info "\u2500" * 60

          import_commands = ImportCommandGeneratorHelper.generate_import_commands(resources)

          ui.info "Example import commands:"
          import_commands.each do |cmd|
            ui.say "  #{Boreal.paint(cmd[:command], :muted)}"
            ui.say "    # #{cmd[:help]}" if cmd[:help]
          end
        end
      end
    end
  end
end
