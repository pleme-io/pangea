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