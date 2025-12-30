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
require_relative 'import/resource_analyzer'
require_relative 'import/import_command_generator'

module Pangea
  module CLI
    module Commands
      # Import command - import existing resources into terraform state
      class Import < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations

        def run(file_path, namespace:, template: nil, resource: nil, id: nil)
          @workspace_manager = Execution::WorkspaceManager.new
          @namespace = namespace
          @file_path = file_path

          # Load namespace configuration
          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          if resource && id
            # Direct import mode
            import_single_resource(resource, id, template, namespace_entity)
          else
            # Interactive import mode
            process_templates(
              file_path: file_path,
              namespace: namespace,
              template_name: template
            ) do |template_name, terraform_json|
              interactive_import(template_name, terraform_json, namespace_entity)
            end
          end
        end

        private

        def import_single_resource(resource_address, resource_id, template_name, _namespace_entity)
          workspace = @workspace_manager.workspace_for(
            namespace: @namespace,
            project: template_name
          )

          unless @workspace_manager.initialized?(workspace)
            ui.error "Workspace not initialized. Run 'pangea plan' first to initialize."
            return
          end

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          ui.info "Importing resource: #{resource_address}"
          ui.info "Resource ID: #{resource_id}"

          result = with_spinner("Importing #{resource_address}...") do
            executor.import_resource(resource_address, resource_id)
          end

          handle_import_result(result, resource_address, executor)
        end

        def handle_import_result(result, resource_address, executor)
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
            ui.warn "Import successful but there are pending changes:"
            display_resource_changes(plan_result[:resource_changes]) if plan_result[:resource_changes]
          else
            ui.success "Import verified - no changes required"
          end
        end

        def interactive_import(template_name, terraform_json, _namespace_entity)
          ui.info "Interactive import for template: #{template_name}"
          ui.info "─" * 60

          resources = Import::ResourceAnalyzer.analyze_resources(terraform_json)

          if resources.empty?
            ui.warn "No resources found in template"
            return
          end

          display_resources(resources)
          display_import_commands(resources)
          setup_and_initialize_workspace(template_name, terraform_json)
        end

        def display_resources(resources)
          ui.info "Resources defined in template:"
          resources.each_with_index do |resource, idx|
            ui.say "  #{idx + 1}. #{ui.pastel.cyan(resource[:address])} (#{resource[:type]})"
            resource[:attributes].each do |key, value|
              ui.say "     #{key}: #{value}" if value
            end
          end
        end

        def display_import_commands(resources)
          ui.info "\nTo import existing AWS resources, you'll need their IDs:"
          ui.info "─" * 60

          import_commands = Import::ImportCommandGenerator.generate_import_commands(resources)

          ui.info "Example import commands:"
          import_commands.each do |cmd|
            ui.say "  #{ui.pastel.bright_black(cmd[:command])}"
            ui.say "    # #{cmd[:help]}" if cmd[:help]
          end
        end

        def setup_and_initialize_workspace(template_name, terraform_json)
          workspace = setup_workspace(
            template_name: template_name,
            terraform_json: terraform_json,
            namespace: @namespace,
            source_file: @file_path
          )

          initialize_workspace_if_needed(workspace)
          display_workspace_instructions(workspace, template_name)
        end

        def initialize_workspace_if_needed(workspace)
          return if @workspace_manager.initialized?(workspace)

          ui.info "\nInitializing terraform..."
          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          init_result = with_spinner("Initializing...") do
            executor.init
          end

          ui.error "Failed to initialize: #{init_result[:error]}" unless init_result[:success]
        end

        def display_workspace_instructions(workspace, template_name)
          ui.info "\nWorkspace ready at: #{workspace}"
          ui.info "\nTo import resources manually, run:"
          ui.say "  cd #{workspace}"
          ui.say "  tofu import RESOURCE_ADDRESS RESOURCE_ID"
          ui.info "\nOr use pangea import with --resource and --id flags:"
          ui.say "  pangea import #{@file_path} --namespace #{@namespace} " \
                 "--template #{template_name} --resource RESOURCE_ADDRESS --id RESOURCE_ID"
        end
      end
    end
  end
end
