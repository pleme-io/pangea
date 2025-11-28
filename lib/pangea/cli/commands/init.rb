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
require 'pangea/cli/ui/template_display'
require 'pangea/cli/ui/command_display'

module Pangea
  module CLI
    module Commands
      # Init command - initialize Terraform workspace
      class Init < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        include UI::TemplateDisplay
        include UI::CommandDisplay

        def run(file_path, namespace:, template: nil)
          @workspace_manager = Execution::WorkspaceManager.new
          @namespace = namespace
          @file_path = file_path
          @start_time = Time.now

          display_command_header('Initialize Terraform Workspace', icon: :initializing)

          # Load namespace configuration
          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          display_namespace_info(namespace_entity)

          # Process templates using shared logic
          process_templates(
            file_path: file_path,
            namespace: namespace,
            template_name: template
          ) do |template_name, terraform_json|
            init_template(template_name, terraform_json, namespace_entity)
          end

          display_execution_time(@start_time, operation: 'Total initialization')
        end

        def init_template(template_name, terraform_json, namespace_entity)
          # Display the compiled template
          display_compiled_template(template_name, terraform_json, show_full: false)

          # Set up workspace
          workspace = setup_workspace(
            template_name: template_name,
            terraform_json: terraform_json,
            namespace: @namespace,
            source_file: @file_path
          )

          display_workspace_info(workspace)

          # Run terraform init with streaming output
          executor = Execution::TerraformExecutor.new(working_dir: workspace)

          formatter.section_header('Initializing Terraform', icon: :initializing)
          formatter.progress_message('Running: tofu init', status: :pending)
          formatter.blank_line

          result = executor.init(stream_output: true)

          formatter.blank_line

          if result[:success]
            display_operation_success('Initialization', details: {
              'Template' => template_name,
              'Workspace' => workspace,
              'Backend' => namespace_entity.state.type.to_s
            })
          else
            display_operation_failure('Initialization', result[:error], details: result[:output])
            exit 1
          end
        end
      end
    end
  end
end
