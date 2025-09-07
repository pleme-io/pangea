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
require 'pangea/version'
require 'pangea/configuration'
require 'pangea/compilation/template_compiler'

module Pangea
  # Agent-friendly API for Pangea operations
  # Provides JSON-based responses for all operations
  class Agent
    attr_reader :options
    
    def initialize(options = {})
      @options = options
      @compiler = Compilation::TemplateCompiler.new
    end
    
    # Get all available resource functions
    def list_resources
      resources = []
      
      Dir.glob(File.join(File.dirname(__FILE__), 'resources', 'aws', '**', '*.rb')).each do |file|
        next if file.include?('/types.rb') || file.include?('_spec.rb')
        
        service = file.split('/')[-2]
        resource = File.basename(file, '.rb')
        
        resources << {
          function: "aws_#{service}_#{resource}",
          service: service,
          resource: resource,
          file: file
        }
      end
      
      {
        total: resources.count,
        resources: resources.sort_by { |r| r[:function] }
      }
    end
    
    # Get all available architecture patterns
    def list_architectures
      architectures = []
      
      Dir.glob(File.join(File.dirname(__FILE__), 'architectures', 'patterns', '**', '*.rb')).each do |file|
        pattern = File.basename(file, '.rb')
        architectures << {
          function: "#{pattern}_architecture",
          pattern: pattern,
          file: file
        }
      end
      
      {
        total: architectures.count,
        architectures: architectures
      }
    end
    
    # Get all available components
    def list_components
      components = []
      
      Dir.glob(File.join(File.dirname(__FILE__), 'components', '**/component.rb')).each do |file|
        component = File.basename(File.dirname(file))
        components << {
          function: "#{component}_component",
          component: component,
          directory: File.dirname(file)
        }
      end
      
      {
        total: components.count,
        components: components
      }
    end
    
    # Analyze a template file
    def analyze_template(file_path, template_name: nil)
      return error_response("File not found: #{file_path}") unless File.exist?(file_path)
      
      templates = @compiler.extract_templates(file_path)
      
      if template_name
        template = templates.find { |t| t[:name].to_s == template_name.to_s }
        return error_response("Template '#{template_name}' not found") unless template
        
        analyze_single_template(template, file_path)
      else
        {
          file: file_path,
          templates: templates.map { |t| analyze_single_template(t, file_path) }
        }
      end
    rescue => e
      error_response(e.message)
    end
    
    # Compile templates to Terraform JSON
    def compile_template(file_path, namespace: nil, template_name: nil)
      return error_response("File not found: #{file_path}") unless File.exist?(file_path)
      
      namespace ||= Pangea.config.default_namespace
      results = @compiler.compile_file(file_path, namespace: namespace, template: template_name)
      
      {
        namespace: namespace,
        results: results.map do |result|
          if result[:success]
            {
              template: result[:name],
              success: true,
              terraform_json: JSON.parse(result[:json])
            }
          else
            {
              template: result[:name],
              success: false,
              error: result[:error]
            }
          end
        end
      }
    rescue => e
      error_response(e.message)
    end
    
    # Validate template syntax
    def validate_template(file_path, template_name: nil)
      return error_response("File not found: #{file_path}") unless File.exist?(file_path)
      
      begin
        templates = @compiler.extract_templates(file_path)
        
        validations = templates.map do |template|
          next if template_name && template[:name].to_s != template_name.to_s
          
          begin
            # Try to compile to validate syntax
            require 'terraform-synthesizer'
            synthesizer = TerraformSynthesizer.new
            synthesizer.instance_eval(template[:content], file_path, template[:line])
            
            {
              template: template[:name],
              valid: true,
              line_number: template[:line]
            }
          rescue => e
            {
              template: template[:name],
              valid: false,
              error: e.message,
              line_number: template[:line]
            }
          end
        end.compact
        
        {
          all_valid: validations.all? { |v| v[:valid] },
          validations: validations
        }
      rescue => e
        error_response(e.message)
      end
    end
    
    # Get namespace configuration
    def get_namespaces
      {
        default: Pangea.config.default_namespace,
        namespaces: Pangea.config.namespaces.map do |ns|
          {
            name: ns.name,
            description: ns.description,
            backend: {
              type: ns.state.type,
              config: sanitize_backend_config(ns)
            }
          }
        end
      }
    rescue => e
      error_response(e.message)
    end
    
    # Get resource function documentation
    def get_resource_info(function_name)
      service, resource = parse_function_name(function_name)
      return error_response("Invalid function name") unless service && resource
      
      file_path = File.join(File.dirname(__FILE__), 'resources', 'aws', service, "#{resource}.rb")
      return error_response("Resource not found") unless File.exist?(file_path)
      
      {
        function: function_name,
        service: service,
        resource: resource,
        file: file_path,
        documentation: extract_documentation(file_path)
      }
    rescue => e
      error_response(e.message)
    end
    
    # Search for resources by keyword
    def search_resources(keyword)
      all_resources = list_resources[:resources]
      
      matches = all_resources.select do |r|
        r[:function].include?(keyword) ||
        r[:service].include?(keyword) ||
        r[:resource].include?(keyword)
      end
      
      {
        keyword: keyword,
        count: matches.count,
        matches: matches
      }
    end
    
    # Generate example code for a resource
    def generate_example(function_name)
      service, resource = parse_function_name(function_name)
      return error_response("Invalid function name") unless service && resource
      
      {
        function: function_name,
        example: generate_resource_example(function_name, service, resource)
      }
    end
    
    private
    
    def analyze_single_template(template, file_path)
      content = template[:content]
      
      {
        name: template[:name],
        file: file_path,
        line_number: template[:line],
        metrics: {
          lines: content.lines.count,
          resources: count_resources(content),
          outputs: count_outputs(content),
          providers: extract_providers(content)
        },
        resource_functions: extract_resource_functions(content),
        architecture_functions: extract_architecture_functions(content),
        dependencies: extract_dependencies(content)
      }
    end
    
    def count_resources(content)
      content.scan(/resource\s+:/).count + content.scan(/aws_\w+\s*\(/).count
    end
    
    def count_outputs(content)
      content.scan(/output\s+:/).count
    end
    
    def extract_providers(content)
      providers = []
      content.scan(/provider\s+:(\w+)/) { |match| providers << match[0] }
      providers.uniq
    end
    
    def extract_resource_functions(content)
      functions = []
      content.scan(/(aws_\w+)\s*\(\s*:(\w+)/) do |func, name|
        functions << { function: func, name: name }
      end
      functions
    end
    
    def extract_architecture_functions(content)
      functions = []
      content.scan(/(\w+_architecture)\s*\(\s*:(\w+)/) do |func, name|
        functions << { function: func, name: name }
      end
      functions
    end
    
    def extract_dependencies(content)
      refs = []
      content.scan(/ref\(:(\w+),\s*:(\w+),\s*:(\w+)\)/) do |type, name, attr|
        refs << { type: type, name: name, attribute: attr }
      end
      refs
    end
    
    def sanitize_backend_config(namespace)
      config = namespace.to_terraform_backend
      
      if config[:s3]
        config[:s3][:kms_key_id] = "***" if config[:s3][:kms_key_id]
      end
      
      config
    end
    
    def parse_function_name(function_name)
      match = function_name.match(/^aws_(\w+)_(\w+)$/)
      return nil unless match
      
      [match[1], match[2]]
    end
    
    def extract_documentation(file_path)
      content = File.read(file_path)
      
      # Extract module comments
      if content.match(/^\s*#\s*(.+?)(?:module|class)/m)
        $1.lines.map(&:strip).map { |l| l.sub(/^#\s*/, '') }.join("\n")
      else
        "No documentation available"
      end
    end
    
    def generate_resource_example(function_name, service, resource)
      <<~RUBY
        # Example usage of #{function_name}
        template :example do
          provider :aws do
            region "us-east-1"
          end
          
          # Create #{resource} in #{service}
          #{function_name}(:my_#{resource}, {
            # Add required attributes here
            name: "example-#{resource}",
            tags: {
              Name: "Example #{resource.gsub('_', ' ').capitalize}",
              Environment: "development"
            }
          })
        end
      RUBY
    end
    
    def error_response(message)
      {
        error: true,
        message: message
      }
    end
  end
end