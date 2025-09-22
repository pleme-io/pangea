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
require 'json'

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
        
        def import_single_resource(resource_address, resource_id, template_name, namespace_entity)
          # Set up workspace
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
          
          if result[:success]
            ui.success "Successfully imported #{resource_address}"
            
            # Run plan to show current state
            ui.info "\nRunning plan to verify import..."
            plan_result = executor.plan
            
            if plan_result[:success]
              if plan_result[:changes]
                ui.warn "Import successful but there are pending changes:"
                display_resource_changes(plan_result[:resource_changes]) if plan_result[:resource_changes]
              else
                ui.success "Import verified - no changes required"
              end
            end
          else
            ui.error "Import failed: #{result[:error]}"
          end
        end
        
        def interactive_import(template_name, terraform_json, namespace_entity)
          ui.info "Interactive import for template: #{template_name}"
          ui.info "─" * 60
          
          # Analyze resources in template
          resources = analyze_resources(terraform_json)
          
          if resources.empty?
            ui.warn "No resources found in template"
            return
          end
          
          ui.info "Resources defined in template:"
          resources.each_with_index do |resource, idx|
            ui.say "  #{idx + 1}. #{ui.pastel.cyan(resource[:address])} (#{resource[:type]})"
            resource[:attributes].each do |key, value|
              ui.say "     #{key}: #{value}" if value
            end
          end
          
          ui.info "\nTo import existing AWS resources, you'll need their IDs:"
          ui.info "─" * 60
          
          # Generate import commands
          import_commands = generate_import_commands(resources)
          
          ui.info "Example import commands:"
          import_commands.each do |cmd|
            ui.say "  #{ui.pastel.bright_black(cmd[:command])}"
            ui.say "    # #{cmd[:help]}" if cmd[:help]
          end
          
          # Set up workspace
          workspace = setup_workspace(
            template_name: template_name,
            terraform_json: terraform_json,
            namespace: @namespace,
            source_file: @file_path
          )
          
          # Check if terraform is initialized
          unless @workspace_manager.initialized?(workspace)
            ui.info "\nInitializing terraform..."
            executor = Execution::TerraformExecutor.new(working_dir: workspace)
            
            init_result = with_spinner("Initializing...") do
              executor.init
            end
            
            unless init_result[:success]
              ui.error "Failed to initialize: #{init_result[:error]}"
              return
            end
          end
          
          ui.info "\nWorkspace ready at: #{workspace}"
          ui.info "\nTo import resources manually, run:"
          ui.say "  cd #{workspace}"
          ui.say "  tofu import RESOURCE_ADDRESS RESOURCE_ID"
          ui.info "\nOr use pangea import with --resource and --id flags:"
          ui.say "  pangea import #{@file_path} --namespace #{@namespace} --template #{template_name} --resource RESOURCE_ADDRESS --id RESOURCE_ID"
        end
        
        def analyze_resources(terraform_json)
          config = JSON.parse(terraform_json)
          resources = []
          
          return resources unless config['resource']
          
          config['resource'].each do |resource_type, instances|
            instances.each do |resource_name, resource_config|
              resources << {
                type: resource_type,
                name: resource_name,
                address: "#{resource_type}.#{resource_name}",
                attributes: extract_key_attributes(resource_type, resource_config),
                config: resource_config
              }
            end
          end
          
          resources
        end
        
        def extract_key_attributes(resource_type, config)
          case resource_type
          when 'aws_route53_zone'
            {
              name: config['name'],
              comment: config['comment']
            }
          when 'aws_route53_record'
            {
              name: config['name'],
              type: config['type'],
              ttl: config['ttl'],
              records: config['records']&.join(', ')
            }
          else
            # Generic attributes
            {
              name: config['name'],
              id: config['id']
            }.compact
          end
        end
        
        def generate_import_commands(resources)
          commands = []
          
          resources.each do |resource|
            case resource[:type]
            when 'aws_route53_zone'
              commands << {
                command: "tofu import #{resource[:address]} ZONE_ID",
                help: "Find zone ID: aws route53 list-hosted-zones --query 'HostedZones[?Name==`#{resource[:attributes][:name]}.`].Id'"
              }
            when 'aws_route53_record'
              commands << {
                command: "tofu import #{resource[:address]} ZONE_ID_#{resource[:attributes][:name]}_#{resource[:attributes][:type]}",
                help: "Format: ZONEID_RECORDNAME_TYPE (e.g., Z123_example.com_A)"
              }
            else
              commands << {
                command: "tofu import #{resource[:address]} RESOURCE_ID",
                help: "Find the resource ID in AWS console or CLI"
              }
            end
          end
          
          commands
        end
      end
    end
  end
end