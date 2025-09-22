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

module Pangea
  module Execution
    # Additional Terraform operations
    module TerraformOperations
      # Get terraform state list
      def state_list
        result = execute_command(['state', 'list', '-no-color'])
        result[:resources] = result[:output].split("\n").reject(&:empty?) if result[:success]
        result
      end
      
      # Validate terraform configuration
      def validate
        result = execute_command(['validate', '-no-color', '-json'])
        parse_validation_output(result) if result[:success]
        result
      end
      
      # Check if terraform binary exists
      def binary_available?
        system("which #{@binary} > /dev/null 2>&1")
      end
      
      # Get terraform version
      def version
        result = execute_command(['version', '-json'])
        parse_version_output(result) if result[:success]
        result
      end
      
      # Import a resource into terraform state
      def import_resource(resource_address, resource_id)
        with_retries do
          result = execute_command(build_import_args(resource_address, resource_id)) do |output|
            if output.include?('Import successful!')
              { success: true, message: 'Resource imported successfully' }
            else
              { success: false, message: 'Import may have failed' }
            end
          end
          handle_retryable_result(result)
          result
        end
      end
      alias import import_resource
      
      # Refresh terraform state
      def refresh
        result = execute_command(['refresh', '-no-color', '-input=false']) do |output|
          if output.include?('Refresh complete') || output.include?('No changes')
            { success: true, message: 'Refresh completed successfully' }
          else
            { success: false, message: 'Refresh may have failed' }
          end
        end
        result
      end
      
      # Format terraform configuration files
      def fmt(check: false, recursive: true)
        result = execute_command(build_fmt_args(check: check, recursive: recursive))
        
        if result[:success]
          formatted_files = result[:output].split("\n").reject(&:empty?)
          result[:formatted_files] = formatted_files
          result[:message] = check ? 'Format check passed' : "Formatted #{formatted_files.length} files"
        else
          result[:message] = 'Format failed'
        end
        
        result
      end
    end
  end
end