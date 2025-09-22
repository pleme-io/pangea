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

require 'pangea/validation/resource_validator'
require 'pangea/logging'

module Pangea
  module Validation
    # Manages validation of resources and provides validation results
    class ValidatorManager
      attr_reader :results, :logger
      
      def initialize
        @results = []
        @logger = Logging.logger.child(component: 'ValidatorManager')
      end
      
      # Validate a resource and store results
      def validate_resource(resource_type, resource_name, attributes)
        @logger.debug "Validating resource", 
                     resource_type: resource_type, 
                     resource_name: resource_name
        
        result = ResourceValidator::Registry.validate(resource_type, attributes)
        
        validation_result = {
          resource_type: resource_type,
          resource_name: resource_name,
          success: result.success?,
          errors: result.errors.to_h,
          warnings: extract_warnings(result)
        }
        
        @results << validation_result
        
        if result.success?
          @logger.debug "Resource validation passed", 
                       resource_type: resource_type,
                       resource_name: resource_name
        else
          @logger.warn "Resource validation failed",
                      resource_type: resource_type,
                      resource_name: resource_name,
                      errors: result.errors.to_h
        end
        
        validation_result
      rescue StandardError => e
        # If no validator exists, log and continue
        @logger.debug "No validator for resource type",
                     resource_type: resource_type,
                     error: e.message
        
        validation_result = {
          resource_type: resource_type,
          resource_name: resource_name,
          success: true,
          errors: {},
          warnings: ["No validator available for resource type: #{resource_type}"]
        }
        
        @results << validation_result
        validation_result
      end
      
      # Validate all resources in a terraform configuration
      def validate_terraform_config(terraform_hash)
        return if terraform_hash.nil? || !terraform_hash.is_a?(Hash)
        
        resources = terraform_hash[:resource] || {}
        
        resources.each do |resource_type, resource_configs|
          resource_configs.each do |resource_name, attributes|
            validate_resource(resource_type, resource_name, attributes)
          end
        end
      end
      
      # Get validation summary
      def summary
        {
          total: @results.size,
          passed: @results.count { |r| r[:success] },
          failed: @results.count { |r| !r[:success] },
          warnings: @results.sum { |r| r[:warnings].size }
        }
      end
      
      # Get failed validations
      def failures
        @results.reject { |r| r[:success] }
      end
      
      # Get all warnings
      def warnings
        @results.flat_map { |r| 
          r[:warnings].map { |w| 
            "#{r[:resource_type]}.#{r[:resource_name]}: #{w}" 
          }
        }
      end
      
      # Check if all validations passed
      def valid?
        @results.all? { |r| r[:success] }
      end
      
      # Clear results
      def clear
        @results.clear
      end
      
      # Generate validation report
      def report
        lines = ["=== Resource Validation Report ==="]
        lines << ""
        
        summary_data = summary
        lines << "Total resources: #{summary_data[:total]}"
        lines << "Passed: #{summary_data[:passed]}"
        lines << "Failed: #{summary_data[:failed]}"
        lines << "Warnings: #{summary_data[:warnings]}"
        lines << ""
        
        if failures.any?
          lines << "=== Validation Failures ==="
          failures.each do |failure|
            lines << "#{failure[:resource_type]}.#{failure[:resource_name]}:"
            format_errors(failure[:errors]).each do |error|
              lines << "  - #{error}"
            end
            lines << ""
          end
        end
        
        if warnings.any?
          lines << "=== Warnings ==="
          warnings.each do |warning|
            lines << "  - #{warning}"
          end
          lines << ""
        end
        
        lines.join("\n")
      end
      
      private
      
      def extract_warnings(result)
        warnings = []
        
        # Add warnings for common issues
        if result.success?
          # Check for potentially problematic configurations
          data = result.to_h
          
          # Example: Check for missing tags
          if !data.key?(:tags) || data[:tags].nil? || data[:tags].empty?
            warnings << "No tags defined - consider adding tags for resource organization"
          end
          
          # Add more warning checks as needed
        end
        
        warnings
      end
      
      def format_errors(errors, prefix = nil)
        messages = []
        
        errors.each do |key, value|
          full_key = prefix ? "#{prefix}.#{key}" : key.to_s
          
          case value
          when Hash
            messages.concat(format_errors(value, full_key))
          when Array
            value.each { |msg| messages << "#{full_key}: #{msg}" }
          else
            messages << "#{full_key}: #{value}"
          end
        end
        
        messages
      end
    end
  end
end