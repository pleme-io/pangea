# frozen_string_literal: true

require 'pangea/cli/commands/base_command'
require 'pangea/compilation/template_compiler'
require 'pangea/compilation/validator'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'
require 'pangea/backends'
require 'pangea/cli/ui/diff'
require 'pangea/cli/ui/progress'
require 'pangea/cli/ui/visualizer'

module Pangea
  module CLI
    module Commands
      # Plan command - show what changes would be made
      class Plan < BaseCommand
        def run(file_path, namespace:, template: nil)
          @workspace_manager = Execution::WorkspaceManager.new
          @diff = UI::Diff.new
          @visualizer = UI::Visualizer.new
          @progress = UI::Progress.new
          @file_path = file_path
          @namespace = namespace
          @template = template
          # Load namespace configuration
          namespace_entity = load_namespace(@namespace)
          return unless namespace_entity
          
          # Compile templates with progress
          result = with_spinner("Compiling templates...") do
            compile_templates(@file_path)
          end
          
          unless result.success
            ui.error "Compilation failed:"
            result.errors.each { |err| ui.error "  #{err}" }
            return
          end
          
          if result.warnings.any?
            ui.warn "Compilation warnings:"
            result.warnings.each { |warn| ui.warn "  #{warn}" }
          end
          
          # Process templates
          if @template
            process_single_template(result, namespace_entity)
          else
            process_all_templates(result, namespace_entity)
          end
        end
          
        def process_single_template(result, namespace_entity)
          return unless result.success
          
          template_name = @template || result.template_name
          plan_template(template_name, result.terraform_json, namespace_entity)
        end
        
        def process_all_templates(result, namespace_entity)
          return unless result.success
          
          if result.template_count && result.template_count > 1
            ui.error "Multiple templates found. Use --template to specify which one to plan."
            return
          end
          
          # Single template case
          template_name = result.template_name || extract_project_from_file(@file_path)
          plan_template(template_name, result.terraform_json, namespace_entity)
        end
        
        def plan_template(template_name, terraform_json, namespace_entity)
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
          
          # Run plan
          plan_file = File.join(workspace, 'plan.tfplan')
          plan_result = with_spinner("Planning changes...") do
            executor.plan(out_file: plan_file)
          end
          
          if plan_result[:success]
            if plan_result[:changes]
              ui.success "Plan generated for template '#{template_name}'"
              ui.info "Plan saved to: #{plan_file}"
              
              # Display beautiful diff
              @diff.terraform_plan(plan_result[:output])
              
              # Show impact analysis
              if plan_result[:resource_changes]
                @visualizer.plan_impact({
                  create: plan_result[:resource_changes][:create] || [],
                  update: plan_result[:resource_changes][:update] || [],
                  destroy: plan_result[:resource_changes][:delete] || [],
                  details: {
                    create: plan_result[:resource_changes][:create]&.map { |r| { type: r.split('.').first, name: r.split('.').last } },
                    update: plan_result[:resource_changes][:update]&.map { |r| { type: r.split('.').first, name: r.split('.').last } },
                    destroy: plan_result[:resource_changes][:delete]&.map { |r| { type: r.split('.').first, name: r.split('.').last } }
                  }
                })
              end
              
              ui.info "\nWorkspace: #{workspace}"
              ui.info "\nTo apply these changes, run:"
              template_flag = @template ? " --template #{@template}" : ""
              ui.info "  pangea apply #{@file_path} --namespace #{@namespace}#{template_flag}"
            else
              ui.info "No changes required for template '#{template_name}'. Infrastructure is up-to-date."
            end
          else
            ui.error "Planning failed for template '#{template_name}':"
            ui.error plan_result[:error] if plan_result[:error]
            ui.error plan_result[:output] if plan_result[:output] && !plan_result[:output].empty?
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
        
        # Removed - using visualizer.plan_impact instead
      end
    end
  end
end