# lib/pangea/utilities/cli/commands/state_command.rb
require_relative '../command'

module Pangea
  module Utilities
    module CLI
      module Commands
        class StateCommand < Command
          desc "Manage cross-template state references"
          
          class_option :namespace, type: :string, aliases: '-n',
                       desc: "Namespace to use"
          class_option :config, type: :string, aliases: '-c',
                       desc: "Configuration file", default: 'pangea.yaml'
          
          def self.banner
            "pangea state SUBCOMMAND [OPTIONS]"
          end
          
          desc "show", "Show template outputs"
          option :template, type: :string, required: true,
                 desc: "Template name"
          def show
            template = options[:template]
            namespace = get_namespace
            
            registry = RemoteState::OutputRegistry.new
            outputs = registry.available_outputs(template)
            
            if outputs.empty?
              warning "No outputs registered for template '#{template}'"
              return
            end
            
            info "Outputs for template '#{template}':"
            outputs['outputs'].each do |name, value|
              say "  #{name}: #{value}"
            end
          end
          
          desc "export", "Export template outputs"
          option :template, type: :string, required: true,
                 desc: "Template name"
          option :output, type: :string,
                 desc: "Specific output to export"
          def export
            template = options[:template]
            namespace = get_namespace
            
            # TODO: Read actual state and export outputs
            info "Exporting outputs from #{template}..."
            
            outputs = {
              vpc_id: "vpc-12345",
              subnet_ids: ["subnet-123", "subnet-456"]
            }
            
            registry = RemoteState::OutputRegistry.new
            registry.register_outputs(template, outputs)
            
            success "Outputs exported successfully"
          end
          
          desc "list", "List templates with available outputs"
          def list
            registry = RemoteState::OutputRegistry.new
            templates = registry.list_templates
            
            if templates.empty?
              info "No templates with registered outputs"
              return
            end
            
            info "Templates with available outputs:"
            templates.each do |template|
              outputs = registry.available_outputs(template)
              say "  #{template} (#{outputs['outputs'].keys.count} outputs)"
            end
          end
          
          desc "deps", "Show template dependencies"
          option :template, type: :string,
                 desc: "Show dependencies for specific template"
          def deps
            manager = RemoteState::DependencyManager.new
            
            # TODO: Load dependencies from templates
            
            if options[:template]
              deps = manager.get_dependencies(options[:template])
              dependents = manager.get_dependents(options[:template])
              
              info "Dependencies for '#{options[:template]}':"
              info "  Depends on: #{deps.join(', ')}" if deps.any?
              info "  Required by: #{dependents.join(', ')}" if dependents.any?
            else
              info "Template dependency order:"
              # Show all dependencies
            end
          end
        end
      end
    end
  end
end