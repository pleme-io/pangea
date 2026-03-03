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
require 'pangea/entities'
require 'pangea/resource_registry'
require 'pangea/component_registry'
require 'pangea/architecture_registry'

module Pangea
  module Compilation
    # Helper methods for template compilation
    module CompilationHelpers
      # Compile a single template internal implementation
      def compile_template_internal(name, content, source_file, template_logger)
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
          
          all_warnings = collect_warnings
          
          Entities::CompilationResult.new(
            success: true,
            terraform_json: json_string,
            template_name: name.to_s,
            warnings: all_warnings
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
  end
end