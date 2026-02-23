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
    module Services
      # Manages Terraform workspaces and initialization.
      # Replaces the WorkspaceOperations mixin.
      class WorkspaceService
        def initialize(workspace_manager:, ui:)
          @manager = workspace_manager
          @ui = ui
        end

        # Create workspace, write TF JSON, save metadata. Returns workspace path.
        def setup(template_name:, terraform_json:, namespace:, source_file:)
          workspace = @manager.workspace_for(namespace: namespace, project: template_name)

          @manager.write_terraform_json(
            workspace: workspace,
            content: JSON.parse(terraform_json)
          )

          @manager.save_metadata(
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

        # Run terraform init if needed. Returns true on success.
        def ensure_initialized(workspace, spinner: nil)
          return true if @manager.initialized?(workspace)

          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          init_result = executor.init

          if init_result[:success]
            true
          else
            @ui.error "Initialization failed: #{init_result[:error] || 'Unknown error'}"
            if init_result[:output] && !init_result[:output].empty?
              @ui.error "Details:"
              init_result[:output].lines.last(10).each { |line| @ui.error "  #{line.chomp}" }
            end
            false
          end
        end

        # Look up an existing workspace path.
        def workspace_for(namespace:, template_name:)
          @manager.workspace_for(namespace: namespace, project: template_name)
        end

        # Check if workspace directory exists.
        def workspace_exists?(workspace)
          Dir.exist?(workspace)
        end

        # Clean workspace directory.
        def clean(workspace)
          @manager.clean(workspace)
        end

        # Read workspace metadata.
        def metadata(workspace)
          @manager.workspace_metadata(workspace)
        end
      end
    end
  end
end
