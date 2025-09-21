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

require 'pangea/compilation/template_compiler'

module Pangea
  module CLI
    module Commands
      # Shared module for processing templates across commands
      module TemplateProcessor
        def process_templates(file_path:, namespace:, template_name: nil)
          result = compile_templates(file_path, namespace, template_name)
          
          unless result.success
            ui.error "Compilation failed:"
            result.errors.each { |err| ui.error "  #{err}" }
            return
          end
          
          display_warnings(result.warnings) if result.warnings.any?
          
          if template_name
            # Process single template
            yield(template_name, result.terraform_json) if block_given?
          elsif multiple_templates?(result)
            # Process multiple templates
            process_multiple_templates(file_path, namespace, result) do |name, json|
              yield(name, json) if block_given?
            end
          else
            # Process single template from result
            name = extract_template_name(result, file_path)
            yield(name, result.terraform_json) if block_given?
          end
        end
        
        private
        
        def compile_templates(file_path, namespace, template_name)
          with_spinner("Compiling templates...") do
            compiler = Compilation::TemplateCompiler.new(
              namespace: namespace,
              template_name: template_name
            )
            compiler.compile_file(file_path)
          end
        rescue => e
          Entities::CompilationResult.new(
            success: false,
            errors: [e.message]
          )
        end
        
        def multiple_templates?(result)
          result.template_count && result.template_count > 1
        end
        
        def process_multiple_templates(file_path, namespace, result)
          ui.info "Multiple templates found. Processing all templates..."
          
          template_names = extract_template_names(result)
          
          template_names.each do |template_name|
            ui.info "\nProcessing template: #{template_name}"
            
            # Recompile with specific template
            compiler = Compilation::TemplateCompiler.new(
              namespace: namespace,
              template_name: template_name
            )
            template_result = compiler.compile_file(file_path)
            
            if template_result.success
              yield(template_name, template_result.terraform_json)
            else
              ui.error "Failed to compile template '#{template_name}':"
              template_result.errors.each { |err| ui.error "  #{err}" }
            end
          end
          
          ui.info "\nAll templates processed."
        end
        
        def extract_template_names(result)
          result.template_name.gsub('Multiple templates: ', '').split(', ')
        end
        
        def extract_template_name(result, file_path)
          result.template_name || extract_project_from_file(file_path)
        end
        
        def extract_project_from_file(file_path)
          basename = File.basename(file_path, '.*')
          basename == 'main' ? nil : basename
        end
        
        def display_warnings(warnings)
          ui.warn "Compilation warnings:"
          warnings.each { |warn| ui.warn "  #{warn}" }
        end
      end
    end
  end
end