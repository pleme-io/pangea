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

require_relative "errors"

module Pangea
  module CLI
    # Centralized error handling for CLI commands
    class ErrorHandler
      attr_reader :ui
      
      def initialize(ui)
        @ui = ui
      end
      
      # Handle different types of errors with consistent formatting
      def handle_error(error, context = {})
        case error
        when CompilationError
          handle_compilation_error(error, context)
        when TerraformError
          handle_terraform_error(error, context)
        when NetworkError
          handle_network_error(error, context)
        when ValidationError
          handle_validation_error(error, context)
        else
          handle_generic_error(error, context)
        end
      end
      
      # Display error with context
      def display_error(title, details, suggestions = nil)
        ui.error "\n#{title}"
        ui.error "─" * title.length
        
        details.each do |detail|
          ui.error "  #{detail}"
        end
        
        if suggestions && suggestions.any?
          ui.info "\nSuggestions:"
          suggestions.each do |suggestion|
            ui.info "  • #{suggestion}"
          end
        end
      end
      
      private
      
      def handle_compilation_error(error, context)
        details = [error.message]
        
        if context[:file_path]
          details << "File: #{context[:file_path]}"
        end
        
        if context[:template]
          details << "Template: #{context[:template]}"
        end
        
        suggestions = [
          "Check syntax errors in your template file",
          "Ensure all required resources are properly imported",
          "Verify that template blocks are properly closed"
        ]
        
        display_error("Template Compilation Error", details, suggestions)
      end
      
      def handle_terraform_error(error, context)
        details = [error.message]
        
        if error.output
          details << "\nTerraform output:"
          details += error.output.lines.map { |line| "  #{line.chomp}" }
        end
        
        suggestions = case error.phase
        when :init
          [
            "Check your backend configuration",
            "Ensure AWS credentials are configured",
            "Verify network connectivity"
          ]
        when :plan
          [
            "Review resource configuration",
            "Check for circular dependencies",
            "Validate provider requirements"
          ]
        when :apply
          [
            "Check AWS service limits",
            "Verify IAM permissions",
            "Review resource dependencies"
          ]
        else
          []
        end
        
        display_error("Terraform Execution Error", details, suggestions)
      end
      
      def handle_network_error(error, context)
        details = [
          error.message,
          ("Service: #{error.service}" if error.respond_to?(:service)),
          ("Timeout: #{error.timeout}s" if error.respond_to?(:timeout))
        ].compact
        
        suggestions = [
          "Check your internet connectivity",
          "Verify firewall settings",
          "Try again with increased timeout"
        ]
        
        display_error("Network Error", details, suggestions)
      end
      
      def handle_validation_error(error, context)
        details = ["Validation failed: #{error.message}"]
        
        if error.respond_to?(:field)
          details << "Field: #{error.field}"
        end
        
        if error.respond_to?(:value)
          details << "Value: #{error.value}"
        end
        
        suggestions = [
          "Review the field requirements",
          "Check the documentation for valid values",
          "Ensure all required fields are provided"
        ]
        
        display_error("Validation Error", details, suggestions)
      end
      
      def handle_generic_error(error, context)
        details = [
          error.message,
          "Type: #{error.class.name}",
          ("Context: #{context.inspect}" if context.any?)
        ].compact
        
        if error.backtrace && ENV['PANGEA_DEBUG']
          details << "\nBacktrace:"
          details += error.backtrace.first(5).map { |line| "  #{line}" }
        end
        
        display_error("Unexpected Error", details)
      end
    end
  end
end