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
require 'pangea/compilation/template_compiler'
require 'pangea/compilation/validator'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'
require 'pangea/backends'

module Pangea
  module CLI
    module Commands
      # Apply command - apply infrastructure changes
      class Apply < BaseCommand
        def run(file_path, namespace:, template: nil, auto_approve: true)
          @workspace_manager = Execution::WorkspaceManager.new
          @file_path = file_path
          @namespace = namespace
          @template = template
          @auto_approve = auto_approve
          
          # Load namespace configuration
          namespace_entity = load_namespace(@namespace)
          return unless namespace_entity
          
          # Compile templates
          result = with_spinner("Compiling templates...") do
            compile_templates(@file_path)
          end
          
          unless result.success
            ui.error "Compilation failed:"
            result.errors.each { |err| ui.error "  #{err}" }
            return
          end
          
          # Process templates
          if @template
            apply_single_template(result, namespace_entity)
          else
            apply_all_templates(result, namespace_entity)
          end
        end
        
        private
        
        def compile_templates(file_path)
          compiler = Compilation::TemplateCompiler.new(
            namespace: @namespace,
            template_name: @template
          )
          compiler.compile_file(file_path)
        rescue => e
          Entities::CompilationResult.new(
            success: false,
            errors: [e.message]
          )
        end
        
        def extract_project_from_file(file_path)
          # Try to extract project name from file path
          basename = File.basename(file_path, '.*')
          basename == 'main' ? nil : basename
        end
        
        def apply_single_template(result, namespace_entity)
          return unless result.success
          
          template_name = @template || result.template_name
          apply_template(template_name, result.terraform_json, namespace_entity)
        end
        
        def apply_all_templates(result, namespace_entity)
          return unless result.success
          
          if result.template_count && result.template_count > 1
            ui.error "Multiple templates found. Use --template to specify which one to apply."
            return
          end
          
          # Single template case
          template_name = result.template_name || extract_project_from_file(@file_path)
          apply_template(template_name, result.terraform_json, namespace_entity)
        end
        
        def apply_template(template_name, terraform_json, namespace_entity)
          # Set up workspace
          workspace = @workspace_manager.workspace_for(
            namespace: @namespace,
            project: template_name
          )
          
          # Write terraform files
          @workspace_manager.write_terraform_json(
            workspace: workspace,
            content: JSON.parse(terraform_json)
          )
          
          # Save metadata
          @workspace_manager.save_metadata(
            workspace: workspace,
            metadata: {
              namespace: @namespace,
              template: template_name,
              source_file: @file_path,
              compilation_time: Time.now.iso8601
            }
          )
          
          # Initialize if needed
          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          
          unless @workspace_manager.initialized?(workspace)
            init_result = with_spinner("Initializing Terraform...") do
              executor.init
            end
            
            unless init_result[:success]
              ui.error "Initialization failed: #{init_result[:error]}"
              return
            end
          end
          
          # Run plan first to show changes if confirmation is required
          unless @auto_approve
            plan_result = with_spinner("Planning changes...") do
              executor.plan
            end
            
            if plan_result[:success]
              if plan_result[:changes]
                # Display changes
                if plan_result[:resource_changes]
                  display_resource_changes(plan_result[:resource_changes])
                end
                
                # Show changes summary
                ui.warn "\nChanges will be applied for template '#{template_name}'."
                ui.warn "Press Ctrl+C within 5 seconds to cancel..."
                sleep 5
                ui.info "Proceeding with apply..."
              else
                ui.info "No changes required for template '#{template_name}'. Infrastructure is up-to-date."
                return
              end
            else
              ui.error "Planning failed. Cannot proceed with apply."
              return
            end
          end
          
          # Apply changes
          apply_result = with_spinner("Applying changes...") do
            executor.apply(auto_approve: true)
          end
          
          if apply_result[:success]
            ui.success "Apply completed successfully for template '#{template_name}'!"
            
            # Show summary
            if apply_result[:added] || apply_result[:changed] || apply_result[:destroyed]
              ui.info "\nSummary:"
              ui.say "  Added: #{apply_result[:added] || 0}", color: :green
              ui.say "  Changed: #{apply_result[:changed] || 0}", color: :yellow
              ui.say "  Destroyed: #{apply_result[:destroyed] || 0}", color: :red
            end
            
            # Show outputs if any
            output_result = executor.output
            if output_result[:success] && output_result[:data] && !output_result[:data].empty?
              ui.info "\nOutputs:"
              output_result[:data].each do |name, data|
                value = data['value']
                ui.say "  #{name}: #{format_output_value(value)}", color: :bright_cyan
              end
            end
          else
            ui.error "Apply failed for template '#{template_name}':"
            ui.error apply_result[:error] if apply_result[:error]
            ui.error apply_result[:output] if apply_result[:output] && !apply_result[:output].empty?
          end
        end
        
        def display_resource_changes(changes)
          ui.info "\nResource changes:"
          
          if changes[:create]&.any?
            ui.info "\n  + Resources to create:", color: :green
            changes[:create].each { |r| ui.say "    #{r}" }
          end
          
          if changes[:update]&.any?
            ui.info "\n  ~ Resources to update:", color: :yellow
            changes[:update].each { |r| ui.say "    #{r}" }
          end
          
          if changes[:replace]&.any?
            ui.info "\n  +/- Resources to replace:", color: :magenta
            changes[:replace].each { |r| ui.say "    #{r}" }
          end
          
          if changes[:delete]&.any?
            ui.info "\n  - Resources to destroy:", color: :red
            changes[:delete].each { |r| ui.say "    #{r}" }
          end
          
          total = changes.values.compact.map(&:count).sum
          ui.say "\nTotal: #{total} resource(s) will be affected", color: :bright_cyan
        end
        
        def format_output_value(value)
          case value
          when String
            value
          when Array
            "[#{value.join(', ')}]"
          when Hash
            value.to_json
          else
            value.to_s
          end
        end
      end
    end
  end
end