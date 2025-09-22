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


require 'terraform-synthesizer'
require 'json'
require 'pangea/types'
require 'pangea/entities'
require 'pangea/resource_registry'
require 'pangea/component_registry'
require 'pangea/architecture_registry'
require 'parallel'
require 'pangea/logging'

module Pangea
  module Compilation
    # Compiles Ruby DSL templates into Terraform JSON
    class TemplateCompiler
      attr_reader :synthesizer, :namespace
      
      def initialize(namespace: nil, template_name: nil)
        @synthesizer = TerraformSynthesizer.new
        @namespace = namespace
        @template_name = template_name
        @templates = {}
        @logger = Logging.logger.child(
          component: 'TemplateCompiler',
          namespace: namespace,
          template: template_name
        )
      end
      
      # Compile templates from a file
      def compile_file(file_path)
        @logger.measure("compile_file", file: file_path) do
          validate_file!(file_path)
          
          content = File.read(file_path)
          @logger.debug "Read file content", size: content.size, lines: content.lines.count
          
          process_requires(content, file_path)
          
          template_blocks = extract_templates(content)
          @logger.info "Extracted templates", count: template_blocks.size, templates: template_blocks.keys
          
          template_blocks = filter_templates(template_blocks, file_path) if @template_name
          
          return template_not_found_error(file_path) if @template_name && template_blocks.empty?
          
          results = compile_all_templates(template_blocks, file_path)
          format_compilation_results(results, template_blocks)
        end
      end
      
      private
      
      def filter_templates(templates, file_path)
        templates.select { |name, _| name.to_s == @template_name.to_s }
      end
      
      def template_not_found_error(file_path)
        Entities::CompilationResult.new(
          success: false,
          errors: ["Template '#{@template_name}' not found in #{file_path}"]
        )
      end
      
      def compile_all_templates(template_blocks, file_path)
        # Use parallel processing for multiple templates
        if template_blocks.size > 1 && !ENV['PANGEA_NO_PARALLEL']
          compile_templates_parallel(template_blocks, file_path)
        else
          compile_templates_sequential(template_blocks, file_path)
        end
      end
      
      def compile_templates_parallel(template_blocks, file_path)
        # Determine thread count based on templates and CPU cores
        thread_count = [template_blocks.size, Parallel.processor_count, 4].min
        @logger.info "Compiling templates in parallel", 
                     template_count: template_blocks.size, 
                     thread_count: thread_count,
                     cpu_count: Parallel.processor_count
        
        results = Parallel.map(template_blocks, in_threads: thread_count) do |name, block_content|
          [name, compile_template(name, block_content, file_path)]
        end
        
        results.to_h
      end
      
      def compile_templates_sequential(template_blocks, file_path)
        template_blocks.map { |name, block_content| 
          [name, compile_template(name, block_content, file_path)] 
        }.to_h
      end
      
      def format_compilation_results(results, template_blocks)
        return results[template_blocks.keys.first] if @template_name
        return results.values.first if results.count == 1
        combine_results(results)
      end
      
      # Compile a single template block
      def compile_template(name, content, source_file)
        template_logger = @logger.child(template_name: name)
        
        template_logger.measure("compile_template") do
          # Create a fresh synthesizer for each template
          @synthesizer = TerraformSynthesizer.new
          
          # Add helper functions (ref, var, etc.)
          require 'pangea/resources/helpers'
          @synthesizer.extend(Pangea::Resources::Helpers)
          
          extend_synthesizer_with_modules
          
          begin
            # The content is already extracted from inside the template block
            # so we can directly evaluate it in the synthesizer context
            template_logger.debug "Evaluating template content", lines: content.lines.count
            @synthesizer.instance_eval(content, source_file, 1)
            
            # Inject backend configuration
            inject_backend_config(name)
            
            # Get the synthesis result
            terraform_json = @synthesizer.synthesis
            resource_count = terraform_json[:resource]&.size || 0
            
            template_logger.info "Template compiled successfully", 
                                resource_count: resource_count,
                                has_provider: !!terraform_json[:provider]
            
            # Convert result to JSON string for storage/output
            json_string = terraform_json.is_a?(String) ? terraform_json : JSON.pretty_generate(terraform_json)
            
            Entities::CompilationResult.new(
              success: true,
              terraform_json: json_string,
              template_name: name.to_s,
              warnings: collect_warnings
            )
            
          rescue SyntaxError => e
            template_logger.error "Syntax error in template", 
                                 error: e.message, 
                                 type: e.class.name
            handle_syntax_error(e, name, source_file)
          rescue StandardError => e
            template_logger.error "Compilation error", 
                                 error: e.message, 
                                 type: e.class.name
            handle_compilation_error(e, name)
          end
        end
      end
      
      def extend_synthesizer_with_modules
        [
          [Pangea::ResourceRegistry.registered_modules, "resource"],
          [Pangea::ComponentRegistry.registered_components, "component"],
          [Pangea::ArchitectureRegistry.registered_architectures, "architecture"]
        ].each do |modules, type|
          @logger.debug "Loading #{type} modules", count: modules.length
          modules.each do |mod|
            @logger.debug "Extending synthesizer", type: type, module: mod
            @synthesizer.extend(mod)
          end
        end
      end
      
      def process_requires(content, file_path)
        content.scan(/^\s*require\s+['"](.+)['"]/).each do |match|
          load_require(match[0], file_path)
        end
      end
      
      def load_require(require_path, file_path)
        @logger.debug "Loading required file", path: require_path
        require require_path
        @logger.debug "Successfully loaded", path: require_path
      rescue LoadError => e
        # Try relative to the file's directory
        relative_path = File.join(File.dirname(file_path), require_path)
        @logger.debug "Trying relative path", path: relative_path
        require relative_path
        @logger.debug "Successfully loaded", path: relative_path
      rescue LoadError => e
        @logger.warn "Could not load required file", 
                     path: require_path, 
                     error: e.message
      end
      
      # Removed unused validation methods
      
      # Removed unused method create_compilation_context
      
      def inject_backend_config(template_name)
        return unless @namespace && defined?(Pangea.config)
        
        namespace_entity = Pangea.config.namespace(@namespace) rescue nil
        return unless namespace_entity
        
        backend_config = prepare_backend_config(namespace_entity, template_name)
        
        @synthesizer.synthesize do
          terraform { backend(backend_config) }
        end
      end
      
      def prepare_backend_config(namespace_entity, template_name)
        config = namespace_entity.to_terraform_backend
        
        case config.keys.first
        when :s3
          config[:s3][:key] = "#{config[:s3][:key]}/#{template_name}/terraform.tfstate"
        when :local
          config[:local][:path] = "#{template_name}.tfstate"
        end
        
        config
      end
      
      def collect_warnings
        synthesis = @synthesizer.synthesis
        
        [].tap do |warnings|
          warnings << "No resources defined in template" if synthesis[:resource].to_a.empty?
          warnings << "No provider configuration found" unless synthesis[:provider]
        end
      end
      
      def extract_templates(content)
        content.scan(/template\s+:(\w+)\s+do\s*\n(.*?)\nend/m).to_h do |name, block_content|
          [name.to_sym, clean_template_content(block_content)]
        end
      end
      
      def clean_template_content(block_content)
        lines = block_content.split("\n")
        return "" if lines.empty?
        
        min_indent = calculate_min_indent(lines)
        lines.map { |line| strip_indent(line, min_indent) }.join("\n")
      end
      
      def calculate_min_indent(lines)
        lines.reject { |line| line.strip.empty? }
             .map { |line| line[/^\s*/].length }
             .min || 0
      end
      
      def strip_indent(line, indent)
        line.strip.empty? ? "" : (line[indent..-1] || line)
      end
      
      # Removed unused AST-related methods
      
      def combine_results(results)
        Entities::CompilationResult.new(
          success: results.values.all?(&:success),
          terraform_json: nil,
          errors: results.values.flat_map(&:errors).compact,
          warnings: results.values.flat_map(&:warnings).compact,
          template_count: results.count,
          template_name: "Multiple templates: #{results.keys.map(&:to_s).join(', ')}"
        )
      end
      
      # Removed unused deep_merge method
      
      
      def validate_file!(file_path)
        raise CompilationError, "File not found: #{file_path}" unless File.exist?(file_path)
        raise CompilationError, "File not readable: #{file_path}" unless File.readable?(file_path)
      end
      
      def debug_log(message)
        @logger.debug message
      end
      
      
      def handle_syntax_error(error, template_name, source_file)
        line_number = error.message[/.*:(\d+):/, 1]
        
        Entities::CompilationResult.new(
          success: false,
          errors: ["Syntax error in template '#{template_name}' at line #{line_number}: #{error.message}"],
          template_name: template_name.to_s
        )
      end
      
      def handle_compilation_error(error, template_name)
        Entities::CompilationResult.new(
          success: false,
          errors: ["Compilation error in template '#{template_name}': #{error.message}"],
          template_name: template_name.to_s
        )
      end
    end
    
    # Compilation-specific errors
    class CompilationError < StandardError; end
  end
end