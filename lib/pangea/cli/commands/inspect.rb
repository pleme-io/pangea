# frozen_string_literal: true

require 'json'
require 'pangea'
require 'pangea/cli/commands/base_command'
require 'pangea/compilation/template_compiler'
require 'pangea/resources'
require 'pangea/architectures'
# require 'pangea/components'  # Temporarily disabled due to Registry issues

module Pangea
  module CLI
    module Commands
      # Inspect command for agent-friendly JSON output
      class Inspect < BaseCommand
        def run(target = nil, type: 'all', template: nil, format: 'json', namespace: nil)
          ui.debug "Inspecting #{type} for target: #{target || 'system'}"
          
          result = case type
          when 'all'
            inspect_all(target, template: template, namespace: namespace)
          when 'templates'
            inspect_templates(target, template: template)
          when 'resources'
            inspect_resources
          when 'architectures'
            inspect_architectures
          when 'components'
            inspect_components
          when 'namespaces'
            inspect_namespaces
          when 'config'
            inspect_config
          when 'state'
            inspect_state(target, template: template, namespace: namespace)
          when 'render'
            render_template(target, template: template, namespace: namespace)
          else
            { error: "Unknown inspection type: #{type}" }
          end
          
          output_result(result, format: format)
        rescue StandardError => e
          output_result({ error: e.message, backtrace: e.backtrace }, format: format)
        end
        
        private
        
        def inspect_all(file, template: nil, namespace: nil)
          {
            metadata: {
              pangea_version: Pangea::VERSION,
              timestamp: Time.now.iso8601,
              file: file,
              template: template,
              namespace: namespace || Pangea.config.default_namespace
            },
            config: inspect_config,
            namespaces: inspect_namespaces,
            templates: file ? inspect_templates(file, template: template) : {},
            resources: inspect_resources_summary,
            architectures: inspect_architectures_summary,
            components: inspect_components_summary
          }
        end
        
        def inspect_templates(file, template: nil)
          return { error: "File required for template inspection" } unless file
          return { error: "File not found: #{file}" } unless File.exist?(file)
          
          compiler = Compilation::TemplateCompiler.new
          templates = compiler.extract_templates(file)
          
          if template
            specific_template = templates.find { |t| t[:name].to_s == template.to_s }
            return { error: "Template '#{template}' not found in #{file}" } unless specific_template
            
            analyze_template(specific_template, file)
          else
            {
              file: file,
              template_count: templates.size,
              templates: templates.map { |t| analyze_template(t, file) }
            }
          end
        end
        
        def analyze_template(template, file)
          {
            name: template[:name],
            line_number: template[:line],
            file: file,
            analysis: {
              providers: extract_providers(template[:content]),
              resources: extract_resources(template[:content]),
              data_sources: extract_data_sources(template[:content]),
              outputs: extract_outputs(template[:content]),
              locals: extract_locals(template[:content]),
              module_calls: extract_module_calls(template[:content]),
              resource_functions: extract_resource_functions(template[:content]),
              architecture_functions: extract_architecture_functions(template[:content]),
              component_functions: extract_component_functions(template[:content])
            }
          }
        end
        
        def extract_providers(content)
          providers = []
          content.scan(/provider\s+:(\w+)/) do |match|
            providers << { type: match[0] }
          end
          providers
        end
        
        def extract_resources(content)
          resources = []
          content.scan(/resource\s+:(\w+),\s*:(\w+)/) do |type, name|
            resources << { type: type, name: name }
          end
          resources
        end
        
        def extract_data_sources(content)
          data_sources = []
          content.scan(/data\s+:(\w+),\s*:(\w+)/) do |type, name|
            data_sources << { type: type, name: name }
          end
          data_sources
        end
        
        def extract_outputs(content)
          outputs = []
          content.scan(/output\s+:(\w+)/) do |match|
            outputs << { name: match[0] }
          end
          outputs
        end
        
        def extract_locals(content)
          locals = []
          content.scan(/locals\s+do(.*?)end/m) do |match|
            # Extract local variable names
            match[0].scan(/(\w+)\s*=/) do |var|
              locals << { name: var[0] }
            end
          end
          locals
        end
        
        def extract_module_calls(content)
          modules = []
          content.scan(/module\s+:(\w+)/) do |match|
            modules << { name: match[0] }
          end
          modules
        end
        
        def extract_resource_functions(content)
          functions = []
          # Match patterns like aws_vpc(:name, {...})
          content.scan(/aws_(\w+)\s*\(\s*:(\w+)/) do |resource, name|
            functions << { 
              function: "aws_#{resource}",
              resource_type: resource,
              name: name 
            }
          end
          functions
        end
        
        def extract_architecture_functions(content)
          functions = []
          # Match architecture pattern functions
          content.scan(/(\w+_architecture)\s*\(\s*:(\w+)/) do |func, name|
            functions << {
              function: func,
              name: name
            }
          end
          functions
        end
        
        def extract_component_functions(content)
          functions = []
          # Match component functions
          content.scan(/(\w+_component)\s*\(\s*:(\w+)/) do |func, name|
            functions << {
              function: func,
              name: name
            }
          end
          functions
        end
        
        def inspect_resources
          resource_modules = []
          
          # Find all resource modules
          Dir.glob(File.join(Pangea::Resources.lib_path, 'aws', '**', '*.rb')).each do |file|
            next if file.include?('/types.rb')
            
            module_path = file.sub(Pangea::Resources.lib_path + '/', '').sub('.rb', '')
            service = module_path.split('/')[1]
            resource = File.basename(module_path)
            
            resource_modules << {
              service: service,
              resource: resource,
              function_name: "aws_#{service}_#{resource}",
              module_path: module_path,
              file: file
            }
          end
          
          {
            total_count: resource_modules.size,
            by_service: resource_modules.group_by { |r| r[:service] }
                                      .transform_values { |resources| 
                                        {
                                          count: resources.size,
                                          resources: resources.map { |r| r[:resource] }.sort
                                        }
                                      },
            resources: resource_modules
          }
        end
        
        def inspect_resources_summary
          resources = inspect_resources
          {
            total_count: resources[:total_count],
            services_count: resources[:by_service].keys.size,
            top_services: resources[:by_service]
                          .sort_by { |_, v| -v[:count] }
                          .first(10)
                          .to_h
          }
        end
        
        def inspect_architectures
          architectures = []
          
          Dir.glob(File.join(Pangea::Architectures.lib_path, 'patterns', '**', '*.rb')).each do |file|
            pattern_name = File.basename(file, '.rb')
            architectures << {
              name: pattern_name,
              function_name: "#{pattern_name}_architecture",
              file: file
            }
          end
          
          {
            total_count: architectures.size,
            architectures: architectures
          }
        end
        
        def inspect_architectures_summary
          archs = inspect_architectures
          {
            total_count: archs[:total_count],
            available: archs[:architectures].map { |a| a[:function_name] }
          }
        end
        
        def inspect_components
          components = []
          
          Dir.glob(File.join(Pangea::Components.lib_path, '**', 'component.rb')).each do |file|
            component_name = File.basename(File.dirname(file))
            components << {
              name: component_name,
              function_name: "#{component_name}_component",
              directory: File.dirname(file),
              has_types: File.exist?(File.join(File.dirname(file), 'types.rb')),
              has_readme: File.exist?(File.join(File.dirname(file), 'README.md'))
            }
          end
          
          {
            total_count: components.size,
            components: components
          }
        end
        
        def inspect_components_summary
          comps = inspect_components
          {
            total_count: comps[:total_count],
            available: comps[:components].map { |c| c[:function_name] }
          }
        end
        
        def inspect_namespaces
          namespaces = Pangea.config.namespaces.map do |ns|
            {
              name: ns.name,
              description: ns.description,
              backend_type: ns.state.type,
              backend_config: sanitize_backend_config(ns),
              tags: ns.tags
            }
          end
          
          {
            default: Pangea.config.default_namespace,
            count: namespaces.size,
            namespaces: namespaces
          }
        end
        
        def sanitize_backend_config(namespace)
          config = namespace.to_terraform_backend
          
          # Remove sensitive values
          if config[:s3]
            config[:s3][:kms_key_id] = "***" if config[:s3][:kms_key_id]
          end
          
          config
        end
        
        def inspect_config
          {
            config_paths: Pangea.config.search_paths,
            config_file: find_config_file,
            default_namespace: Pangea.config.default_namespace,
            terraform_binary: Pangea.config.fetch(:terraform, :binary, default: 'tofu'),
            modules_path: Pangea.config.fetch(:modules, :path, default: 'modules'),
            cache_directory: Pangea.config.fetch(:cache, :directory, default: '~/.pangea/cache')
          }
        end
        
        def find_config_file
          Pangea.config.search_paths.each do |path|
            %w[pangea.yml pangea.yaml].each do |filename|
              file = File.join(path, filename)
              return file if File.exist?(file)
            end
          end
          nil
        end
        
        def inspect_state(file, template: nil, namespace: nil)
          return { error: "File required for state inspection" } unless file
          
          namespace ||= Pangea.config.default_namespace
          ns = Pangea.config.namespace(namespace)
          return { error: "Namespace '#{namespace}' not found" } unless ns
          
          compiler = Compilation::TemplateCompiler.new
          templates = compiler.extract_templates(file)
          
          if template
            templates = templates.select { |t| t[:name].to_s == template.to_s }
          end
          
          state_info = templates.map do |tmpl|
            workspace_dir = compiler.workspace_directory(namespace, tmpl[:name])
            state_file = case ns.state.type
                        when 'local'
                          File.join(workspace_dir, ns.state.config.path || 'terraform.tfstate')
                        when 's3'
                          "s3://#{ns.state.config.bucket}/#{ns.state.config.key}/#{tmpl[:name]}/terraform.tfstate"
                        end
            
            {
              template: tmpl[:name],
              namespace: namespace,
              backend_type: ns.state.type,
              state_location: state_file,
              workspace_directory: workspace_dir,
              initialized: Dir.exist?(File.join(workspace_dir, '.terraform'))
            }
          end
          
          {
            namespace: namespace,
            backend_type: ns.state.type,
            templates: state_info
          }
        end
        
        def render_template(file, template: nil, namespace: nil)
          return { error: "File required for rendering" } unless file
          return { error: "File not found: #{file}" } unless File.exist?(file)
          
          namespace ||= Pangea.config.default_namespace
          compiler = Compilation::TemplateCompiler.new
          
          begin
            results = compiler.compile_file(file, namespace: namespace, template: template)
            
            results.map do |result|
              {
                template: result[:name],
                namespace: namespace,
                success: result[:success],
                json: result[:success] ? JSON.parse(result[:json]) : nil,
                error: result[:error],
                terraform_version: result[:terraform_version]
              }
            end
          rescue => e
            { error: "Compilation failed: #{e.message}" }
          end
        end
        
        def output_result(result, format: 'json')
          case format
          when 'json'
            puts JSON.pretty_generate(result)
          when 'yaml'
            require 'yaml'
            puts result.to_yaml
          else
            ui.error "Unknown format: #{format}"
          end
        end
      end
    end
  end
end