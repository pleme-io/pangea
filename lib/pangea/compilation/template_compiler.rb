# frozen_string_literal: true

require 'terraform-synthesizer'
require 'json'
require 'pangea/types'
require 'pangea/entities'
require 'pangea/resource_registry'
require 'pangea/component_registry'
require 'pangea/architecture_registry'

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
      end
      
      # Compile templates from a file
      def compile_file(file_path)
        validate_file!(file_path)
        
        content = File.read(file_path)
        
        # Process requires to register components/resources
        process_requires(content, file_path)
        
        # Extract templates using a custom parser
        template_blocks = extract_templates(content)
        
        # Filter to specific template if requested
        if @template_name
          template_blocks = template_blocks.select { |name, _| name.to_s == @template_name.to_s }
          
          if template_blocks.empty?
            return Entities::CompilationResult.new(
              success: false,
              errors: ["Template '#{@template_name}' not found in #{file_path}"]
            )
          end
        end
        
        # Compile each template
        results = {}
        template_blocks.each do |name, block_content|
          results[name] = compile_template(name, block_content, file_path)
        end
        
        # Return combined results
        if @template_name
          # Return the result for the specific template
          template_key = template_blocks.keys.first
          results[template_key]
        elsif results.count == 1
          # Single template case - return the template directly instead of combining
          results.values.first
        else
          # Multiple templates case - combine results
          combine_results(results)
        end
      end
      
      # Compile a single template block
      def compile_template(name, content, source_file)
        # Create a fresh synthesizer for each template
        @synthesizer = TerraformSynthesizer.new
        
        # Add helper functions (ref, var, etc.)
        require 'pangea/resources/helpers'
        @synthesizer.extend(Pangea::Resources::Helpers)
        
        # Automatically extend with all registered resource modules
        # User controls what's available via requires in their infrastructure files
        Pangea::ResourceRegistry.registered_modules.each do |mod|
          @synthesizer.extend(mod)
        end
        
        # Automatically extend with all registered component modules
        # Components have access to resources, so load them after resources
        puts "[DEBUG] Registered components: #{Pangea::ComponentRegistry.registered_components.length}" if ENV['PANGEA_DEBUG']
        Pangea::ComponentRegistry.registered_components.each do |comp|
          puts "[DEBUG] Extending synthesizer with component: #{comp}" if ENV['PANGEA_DEBUG']
          @synthesizer.extend(comp)
        end
        
        # Automatically extend with all registered architecture modules
        # Architectures have access to resources and components, so load them last
        puts "[DEBUG] Registered architectures: #{Pangea::ArchitectureRegistry.registered_architectures.length}" if ENV['PANGEA_DEBUG']
        Pangea::ArchitectureRegistry.registered_architectures.each do |arch|
          puts "[DEBUG] Extending synthesizer with architecture: #{arch}" if ENV['PANGEA_DEBUG']
          @synthesizer.extend(arch)
        end
        
        begin
          # The content is already extracted from inside the template block
          # so we can directly evaluate it in the synthesizer context
          @synthesizer.instance_eval(content, source_file, 1)
          
          # Inject backend configuration
          inject_backend_config(name)
          
          # Get the synthesis result
          terraform_json = @synthesizer.synthesis
          
          # Convert result to JSON string for storage/output
          json_string = terraform_json.is_a?(String) ? terraform_json : JSON.pretty_generate(terraform_json)
          
          Entities::CompilationResult.new(
            success: true,
            terraform_json: json_string,
            template_name: name.to_s,
            warnings: collect_warnings
          )
          
        rescue SyntaxError => e
          handle_syntax_error(e, name, source_file)
        rescue StandardError => e
          handle_compilation_error(e, name)
        end
      end
      
      private
      
      def process_requires(content, file_path)
        # Extract and execute require statements to register components
        content.each_line do |line|
          if line =~ /^\s*require\s+['"](.+)['"]/
            require_path = $1
            begin
              puts "[DEBUG] Processing require: #{require_path}" if ENV['PANGEA_DEBUG']
              require require_path
            rescue LoadError => e
              # Try relative to the file's directory
              begin
                require File.join(File.dirname(file_path), require_path)
              rescue LoadError
                # Ignore if can't load - might be optional
                puts "[DEBUG] Could not load: #{require_path}" if ENV['PANGEA_DEBUG']
              end
            end
          end
        end
      end
      
      def validate_template!(template)
        template.validate!
      rescue Entities::ValidationError => e
        raise CompilationError, "Template validation failed: #{e.message}"
      end
      
      def compile_content(content)
        # Create a clean binding for evaluation
        context = create_compilation_context
        
        # Evaluate in the synthesizer's context
        @synthesizer.instance_eval(content, "(inline)", 1)
      end
      
      def create_compilation_context(template = nil)
        # This would include helper methods available in templates
        Module.new do
          def var(name)
            # Variable interpolation logic
          end
          
          def import(module_name)
            # Module import logic
          end
        end
      end
      
      def inject_backend_config(template_name)
        return unless @namespace
        
        # Skip if no namespace configured
        return unless defined?(Pangea.config) && @namespace
        
        # Load namespace entity
        namespace_entity = Pangea.config.namespace(@namespace) rescue nil
        return unless namespace_entity
        
        # Get backend config 
        backend_config = namespace_entity.to_terraform_backend
        
        # Add template-specific state isolation for S3 backends
        if backend_config[:s3]
          original_key = backend_config[:s3][:key]
          # Generate template-specific state key: original_key + template_name
          backend_config[:s3][:key] = "#{original_key}/#{template_name}/terraform.tfstate"
        elsif backend_config[:local]
          # For local backends, use template-specific directory
          backend_config[:local][:path] = "#{template_name}.tfstate"
        end
        
        # Always inject backend configuration for template isolation
        @synthesizer.synthesize do
          terraform do
            backend(backend_config)
          end
        end
      end
      
      def collect_warnings
        warnings = []
        
        # Check for common issues
        synthesis = @synthesizer.synthesis
        
        if synthesis[:resource].nil? || synthesis[:resource].empty?
          warnings << "No resources defined in template"
        end
        
        if synthesis[:provider].nil?
          warnings << "No provider configuration found"
        end
        
        warnings
      end
      
      def extract_templates(content)
        templates = {}
        
        # Use regex parsing to extract template blocks
        # This regex captures the template name and everything between do...end
        content.scan(/template\s+:(\w+)\s+do\s*\n(.*?)\nend/m) do |name, block_content|
          # Clean up the block content - remove leading whitespace uniformly
          lines = block_content.split("\n")
          if lines.any?
            # Find minimum indentation (excluding empty lines)
            min_indent = lines.reject { |line| line.strip.empty? }
                             .map { |line| line[/^\s*/].length }
                             .min || 0
            
            # Remove the common indentation
            cleaned_lines = lines.map do |line|
              if line.strip.empty?
                ""
              else
                line[min_indent..-1] || line
              end
            end
            
            templates[name.to_sym] = cleaned_lines.join("\n")
          end
        end
        
        templates
      end
      
      def extract_templates_from_ast(node, content, templates, depth = 0)
        return unless node.respond_to?(:children)
        
        node.children.each do |child|
          next unless child.is_a?(RubyVM::AbstractSyntaxTree::Node)
          
          # Look for method calls named 'template'
          if child.type == :FCALL && child.children[0] == :template
            # Extract template name and block
            if child.children[1] && child.children[1].children[0] &&
               child.children[1].children[0].type == :LIST &&
               child.children[1].children[0].children[0] &&
               child.children[1].children[0].children[0].type == :LIT
              
              template_name = child.children[1].children[0].children[0].children[0].to_s
              
              # Extract block content using line numbers
              start_line = child.first_lineno
              end_line = child.last_lineno
              
              if start_line && end_line
                lines = content.lines
                # Find the actual template block content
                template_content = extract_block_content(lines, start_line, end_line)
                templates[template_name] = template_content
              end
            end
          end
          
          # Recursively search child nodes
          extract_templates_from_ast(child, content, templates, depth + 1)
        end
      end
      
      def extract_block_content(lines, start_line, end_line)
        # Extract content between template do...end, excluding the template line itself
        template_lines = lines[(start_line - 1)..(end_line - 1)]
        
        # Remove first line (template declaration) and last line (end)
        content_lines = template_lines[1..-2] || []
        
        # Remove common indentation
        if content_lines.any?
          min_indent = content_lines.reject(&:strip).empty? ? 0 : 
                      content_lines.map { |line| line[/^\s*/].length }.min
          content_lines = content_lines.map { |line| line[min_indent..-1] || line }
        end
        
        content_lines.join
      end
      
      def combine_results(results)
        success = results.values.all?(&:success)
        errors = results.values.flat_map(&:errors).compact
        warnings = results.values.flat_map(&:warnings).compact
        
        # For multiple templates, we DON'T combine JSON - each is separate workspace
        # Return info about all templates found
        template_names = results.keys.map(&:to_s).join(', ')
        
        Entities::CompilationResult.new(
          success: success,
          terraform_json: nil,  # No combined JSON - each template is separate
          errors: errors,
          warnings: warnings,
          template_count: results.count,
          template_name: "Multiple templates: #{template_names}"
        )
      end
      
      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |_, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge(old_val, new_val)
          elsif old_val.is_a?(Array) && new_val.is_a?(Array)
            old_val + new_val
          else
            new_val
          end
        end
      end
      
      
      def validate_file!(file_path)
        unless File.exist?(file_path)
          raise CompilationError, "File not found: #{file_path}"
        end
        
        unless File.readable?(file_path)
          raise CompilationError, "File not readable: #{file_path}"
        end
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