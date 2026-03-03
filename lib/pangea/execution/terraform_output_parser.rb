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
    # Parses Terraform command outputs
    module TerraformOutputParser
      # Error patterns to extract from Terraform output
      ERROR_PATTERNS = [
        /Error: (.+?)\n/,
        /│ Error: (.+)/,
        /Failed to (.+)/
      ].freeze
      
      # Parse apply output for results
      def parse_apply_output(output)
        return { success: false, message: 'Apply may have failed' } unless output.include?('Apply complete!')
        
        resources_match = output.match(/(\d+) added, (\d+) changed, (\d+) destroyed/)
        base_result = { success: true, message: 'Apply completed successfully' }
        
        return base_result unless resources_match
        
        base_result.merge(
          added: resources_match[1].to_i,
          changed: resources_match[2].to_i,
          destroyed: resources_match[3].to_i
        )
      end
      
      # Parse plan output for resource changes
      def parse_plan_output(output)
        changes = {
          create: [],
          update: [],
          delete: [],
          replace: []
        }
        
        output.lines.each do |line|
          case line
          when /^\s*\+\s+(.+)$/
            changes[:create] << $1.strip
          when /^\s*~\s+(.+)$/
            changes[:update] << $1.strip
          when /^\s*-\s+(.+)$/
            changes[:delete] << $1.strip
          when /^\s*\+\/\-\s+(.+)$/
            changes[:replace] << $1.strip
          end
        end
        
        changes
      end
      
      # Extract meaningful error messages from Terraform output
      def extract_terraform_error(output)
        return output if output.nil? || output.empty?
        
        # Try to match specific error patterns first
        ERROR_PATTERNS.each do |pattern|
          match = output.match(pattern)
          return match[1] if match
        end
        
        # Fallback to line-based error extraction
        error_lines = output.lines.select do |line|
          line.include?('Error:') || 
          line.include?('Failed to') ||
          line.include?('Could not') ||
          line.include?('Unable to') ||
          line.include?('Invalid') ||
          line.include?('Missing')
        end
        
        if error_lines.any?
          error_lines.join("\n").strip
        else
          # Return the last few meaningful lines if no specific error found
          output.lines.reject(&:empty?).last(5).join("\n").strip
        end
      end
      
      # Parse version output
      def parse_version_output(result)
        return result unless result[:success]
        
        begin
          version_data = JSON.parse(result[:output])
          result[:version] = version_data['terraform_version']
        rescue JSON::ParserError
          # Try non-JSON format
          version_match = result[:output].match(/Terraform v(\d+\.\d+\.\d+)/)
          result[:version] = version_match[1] if version_match
        end
        
        result
      end
      
      # Parse validation output
      def parse_validation_output(result)
        return result unless result[:success]
        
        begin
          validation = JSON.parse(result[:output])
          result[:valid] = validation['valid']
          result[:errors] = validation['diagnostics'] || []
        rescue JSON::ParserError
          result[:success] = false
          result[:error] = 'Failed to parse validation output'
        end
        
        result
      end
    end
  end
end