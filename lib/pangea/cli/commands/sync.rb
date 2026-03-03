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

module Pangea
  module CLI
    module Commands
      # Sync command - refresh state from cloud provider without making changes
      class Sync < BaseCommand
        def run(file_path, namespace:, template: nil)
          templates   = Services::TemplateService.new(ui: ui)
          @workspaces = Services::WorkspaceService.new(
            workspace_manager: Execution::WorkspaceManager.new, ui: ui
          )
          @namespace = namespace
          @file_path = file_path

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          templates.process_all(
            file_path: file_path, namespace: namespace, template_name: template
          ) do |name, json|
            sync_template(name, json)
          end
        end

        private

        def sync_template(template_name, terraform_json)
          ui.info "Syncing state for template '#{template_name}'..."

          workspace = @workspaces.setup(
            template_name: template_name, terraform_json: terraform_json,
            namespace: @namespace, source_file: @file_path
          )

          return unless @workspaces.ensure_initialized(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          refresh_result = with_spinner("Refreshing state from cloud provider...") do
            executor.refresh
          end

          if refresh_result[:success]
            ui.success "State synced successfully for template '#{template_name}'"
            display_state_summary(executor, template_name)
            ui.info "\nWorkspace: #{workspace}"
          else
            ui.error "Sync failed for template '#{template_name}':"
            ui.error refresh_result[:error] if refresh_result[:error]
            ui.error refresh_result[:output] if refresh_result[:output] && !refresh_result[:output].empty?
          end
        end

        def display_state_summary(executor, template_name)
          state_result = executor.state_list
          return unless state_result[:success] && state_result[:resources]&.any?

          ui.info "\nCurrent State Summary for '#{template_name}':"
          ui.info "\u2500" * 50

          grouped = state_result[:resources].group_by { |r| r.split('.').first }
          grouped.each do |type, resources|
            ui.say "  #{Boreal.paint(type, :primary)}: #{resources.count} resource(s)"
            resources.each do |resource|
              ui.say "    - #{Boreal.paint(resource.split('.', 2).last, :muted)}"
            end
          end

          ui.info "\nTotal: #{state_result[:resources].count} resources in state"
        end
      end
    end
  end
end
