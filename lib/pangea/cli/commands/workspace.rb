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
require 'pangea/cli/services/architecture_service'
require 'pangea/cli/services/workspace_service'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'
require 'pangea/aws/sso_validator'

module Pangea
  module CLI
    module Commands
      # Workspace command — architecture-based infrastructure lifecycle.
      #
      # Usage:
      #   pangea workspace plan <workspace-name>
      #   pangea workspace apply <workspace-name>
      #   pangea workspace destroy <workspace-name>
      #   pangea workspace show <workspace-name>
      #   pangea workspace status <workspace-name>
      #   pangea workspace migrate <workspace-name>
      #   pangea workspace list
      class Workspace < BaseCommand
        ACTIONS = %w[plan apply destroy show status migrate list].freeze

        def run(action, workspace_name = nil, auto_approve: true)
          unless ACTIONS.include?(action)
            ui.error "Unknown workspace action: #{action}"
            ui.say "Available actions: #{ACTIONS.join(', ')}"
            exit 1
          end

          return list_workspaces if action == 'list'

          unless workspace_name
            ui.error "Workspace name is required for '#{action}'"
            exit 1
          end

          ws_config = load_workspace_config(workspace_name)
          validate_aws_sso(ws_config)

          case action
          when 'plan'    then workspace_plan(ws_config)
          when 'apply'   then workspace_apply(ws_config, auto_approve: auto_approve)
          when 'destroy' then workspace_destroy(ws_config, auto_approve: auto_approve)
          when 'show'    then workspace_show(ws_config)
          when 'status'  then workspace_status(ws_config)
          when 'migrate' then workspace_migrate(ws_config)
          end
        end

        private

        def architecture_service
          @architecture_service ||= Services::ArchitectureService.new(ui: ui)
        end

        def workspace_manager
          @workspace_manager ||= Execution::WorkspaceManager.new
        end

        def workspace_service
          @workspace_service ||= Services::WorkspaceService.new(
            workspace_manager: workspace_manager, ui: ui
          )
        end

        def load_workspace_config(name)
          ws = Pangea.config.schema.get_workspace(name)
          unless ws
            ui.error "Workspace '#{name}' not found in pangea.yml workspaces section"
            available = Pangea.config.schema.workspace_configs.keys.map(&:to_s)
            ui.say "Available workspaces: #{available.join(', ')}" if available.any?
            exit 1
          end
          ws
        end

        def validate_aws_sso(ws_config)
          return unless ws_config.aws_profile

          AWS::SSOValidator.validate!(ws_config.aws_profile)
          AWS::SSOValidator.configure_environment!(ws_config.aws_profile)
        rescue AWS::SSOSessionExpired => e
          ui.error e.message
          exit 1
        end

        # ── Actions ─────────────────────────────────────────────────────

        def workspace_plan(ws_config)
          ui.info "--- #{ws_config.name}: plan ---"
          terraform_json = synthesize(ws_config)
          workspace = setup_workspace(ws_config, terraform_json)
          return unless ensure_initialized(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          plan_file = File.join(workspace, 'plan.tfplan')
          result = with_spinner('Planning changes...') { executor.plan(out_file: plan_file) }

          if result[:success]
            if result[:changes]
              ui.info "Changes detected. Review with: pangea workspace show #{ws_config.name}"
            else
              ui.info 'No changes. Infrastructure is up-to-date.'
            end
          else
            ui.error "Plan failed: #{result[:error]}"
          end
        end

        def workspace_apply(ws_config, auto_approve:)
          ui.info "--- #{ws_config.name}: apply ---"
          terraform_json = synthesize(ws_config)
          workspace = setup_workspace(ws_config, terraform_json)
          return unless ensure_initialized(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          plan_result = with_spinner('Planning changes...') { executor.plan }
          unless plan_result[:success]
            ui.error "Plan failed: #{plan_result[:error]}"
            return
          end

          unless plan_result[:changes]
            ui.info 'No changes. Infrastructure is up-to-date.'
            return
          end

          result = with_spinner('Applying changes...') { executor.apply(auto_approve: auto_approve) }

          if result[:success]
            ui.info "Apply complete for workspace '#{ws_config.name}'."
          else
            ui.error "Apply failed: #{result[:error]}"
          end
        end

        def workspace_destroy(ws_config, auto_approve:)
          ui.info "--- #{ws_config.name}: destroy ---"
          namespace = ws_config.namespace || 'default'
          workspace = workspace_manager.workspace_for(namespace: namespace, project: ws_config.name)

          unless Dir.exist?(workspace)
            ui.error "No workspace directory found for '#{ws_config.name}'"
            return
          end

          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          result = with_spinner('Destroying resources...') { executor.destroy(auto_approve: auto_approve) }

          if result[:success]
            ui.info "Destroy complete for workspace '#{ws_config.name}'."
          else
            ui.error "Destroy failed: #{result[:error]}"
          end
        end

        def workspace_show(ws_config)
          ui.info "--- #{ws_config.name}: show ---"
          namespace = ws_config.namespace || 'default'
          workspace = workspace_manager.workspace_for(namespace: namespace, project: ws_config.name)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          result = executor.output
          if result[:success]
            ui.say result[:output]
          else
            ui.error "Show failed: #{result[:error]}"
          end
        end

        def workspace_status(ws_config)
          namespace = ws_config.namespace || 'default'
          workspace = workspace_manager.workspace_for(namespace: namespace, project: ws_config.name)

          ui.info "Workspace:    #{ws_config.name}"
          ui.info "Architecture: #{ws_config.architecture}"
          ui.info "Namespace:    #{namespace}"
          ui.info "Directory:    #{workspace}"
          ui.info "Initialized:  #{workspace_manager.initialized?(workspace)}"

          metadata = workspace_manager.workspace_metadata(workspace)
          ui.info "Last updated: #{metadata[:updated_at]}" if metadata[:updated_at]

          # Check migration status
          migrated = File.exist?(File.join(workspace, '.backend-migrated'))
          ui.info "Migrated:     #{migrated}" if ws_config.remote_backend
        end

        def workspace_migrate(ws_config)
          unless ws_config.remote_backend
            ui.error "No remote_backend configured for workspace '#{ws_config.name}'."
            ui.say 'Add remote_backend to the workspace definition in pangea.yml to enable migration.'
            exit 1
          end

          namespace = ws_config.namespace || 'default'
          workspace = workspace_manager.workspace_for(namespace: namespace, project: ws_config.name)

          marker = File.join(workspace, '.backend-migrated')
          if File.exist?(marker)
            ui.info "Workspace '#{ws_config.name}' is already using remote backend."
            return
          end

          ui.info "--- #{ws_config.name}: migrate ---"

          # Rewrite backend.tf.json to remote backend
          remote_config = ws_config.remote_backend_config
          backend_json = { terraform: { backend: remote_config.to_terraform_backend } }
          workspace_manager.write_terraform_json(
            workspace: workspace,
            content: backend_json,
            filename: 'backend.tf.json'
          )

          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          # Run init -migrate-state (requires interactive confirmation)
          ui.info 'Running tofu init -migrate-state...'
          result = executor.init(migrate_state: true)

          if result[:success]
            # Drop migration marker
            File.write(marker, <<~MARKER)
              migrated=#{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}
              type=#{ws_config.remote_backend[:type] || 's3'}
            MARKER

            # Clean local state
            %w[terraform.tfstate terraform.tfstate.backup].each do |f|
              path = File.join(workspace, f)
              FileUtils.rm_f(path) if File.exist?(path)
            end

            ui.info "State migrated to remote backend for '#{ws_config.name}'."
            ui.info 'All future operations will use the remote backend automatically.'
          else
            ui.error "Migration failed: #{result[:error]}"
          end
        end

        # ── Helpers ─────────────────────────────────────────────────────

        def synthesize(ws_config)
          with_spinner("Synthesizing #{ws_config.architecture}...") do
            architecture_service.synthesize(ws_config)
          end
        end

        def setup_workspace(ws_config, terraform_json)
          namespace = ws_config.namespace || 'default'
          workspace_service.setup(
            template_name: ws_config.name,
            terraform_json: terraform_json,
            namespace: namespace,
            source_file: 'pangea.yml'
          )
        end

        def ensure_initialized(workspace)
          workspace_service.ensure_initialized(workspace)
        end

        def list_workspaces
          workspaces = Pangea.config.schema.workspace_configs
          if workspaces.empty?
            ui.info 'No workspaces defined in pangea.yml.'
            return
          end

          ui.info "Workspaces (#{workspaces.size}):"
          workspaces.each do |name, ws|
            ui.say "  #{name} — architecture: #{ws.architecture}, backend: #{ws.backend.type}"
          end
        end
      end
    end
  end
end
