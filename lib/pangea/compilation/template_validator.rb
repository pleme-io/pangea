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

require 'pangea/validation'

module Pangea
  module Compilation
    # Handles template validation and warnings
    module TemplateValidator
      # Collect warnings from synthesis result
      def collect_warnings
        synthesis = @synthesizer.synthesis
        
        [].tap do |warnings|
          warnings << "No resources defined in template" if synthesis[:resource].to_a.empty?
          warnings << "No provider configuration found" unless synthesis[:provider]
        end
      end
      
      # Validate resources in terraform configuration
      def validate_resources(terraform_json, template_name, logger)
        validator = Validation::ValidatorManager.new
        
        logger.debug "Validating resources in template", template_name: template_name
        
        # Validate all resources in the terraform configuration
        validator.validate_terraform_config(terraform_json)
        
        # Collect warnings from validation
        warnings = []
        
        # Add validation failures as warnings (not errors, to maintain backward compatibility)
        if validator.failures.any?
          logger.warn "Resource validation found issues", 
                     template_name: template_name,
                     failed_count: validator.failures.size
          
          validator.failures.each do |failure|
            resource_id = "#{failure[:resource_type]}.#{failure[:resource_name]}"
            failure[:errors].each do |field, errors|
              error_list = errors.is_a?(Array) ? errors : [errors]
              error_list.each do |error|
                warnings << "#{resource_id}: #{field} #{error}"
              end
            end
          end
        end
        
        # Add general warnings
        warnings.concat(validator.warnings)
        
        logger.debug "Resource validation complete",
                    total: validator.summary[:total],
                    passed: validator.summary[:passed],
                    failed: validator.summary[:failed],
                    warnings: warnings.size
        
        warnings
      end
      
      # Validate file exists and is readable
      def validate_file!(file_path)
        raise CompilationError, "File not found: #{file_path}" unless File.exist?(file_path)
        raise CompilationError, "File not readable: #{file_path}" unless File.readable?(file_path)
      end
      
      # Create error result for template not found
      def template_not_found_error(file_path)
        Entities::CompilationResult.new(
          success: false,
          errors: ["Template '#{@template_name}' not found in #{file_path}"]
        )
      end
    end
  end
end